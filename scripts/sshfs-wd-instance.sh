#!/bin/bash

# set defaults
name=
enabled=1
remoteHost=aaa
remotePath=/
localPath=
fuseOpts="reconnect,ServerAliveInterval=5,ServerAliveCountMax=3"
pollInterval=1
positiveThreshold=3
negativeThreshold=60
interactive=1


source "$base/scripts/commons.sh"

configFile="$1"


function failIfEmpty {
  if [ -z "$2" ]; then
    echo "Config file parameter $1 is mandatory"
    exit 1
  fi
}

# config processing part
# first parameter expected to be a path to config file
echo "Starting sshfs watchdog instance for $configFile"

source "$configFile"

if (( enabled != 1 )); then
  echo "enabled=$enabled in config file. Exiting..."
  exit 1
fi

# check mandatory parameters
if [ -z "$name" ]; then
  echo "No name specified inside $configFile"
  name=$(echo "$configFile" | cut -f 1 -d '.')
  echo "Assuming name=$name"
fi
failIfEmpty "remoteHost" "${remoteHost}"
failIfEmpty "localPath" "${localPath}"

export name="$name"
export remoteHost="$remoteHost"
export remotePath="$remotePath"
export localPath="$localPath"
export fuseOpts="$fuseOpts"
export pollInterval="$pollInterval"
export positiveThreshold="$positiveThreshold"
export negativeThreshold="$negativeThreshold"
export interactive="$interactive"


function connect {
  #local resultCode=0

  if [ "$interactive" == "1" ]; then
    while :
    do
      resultOutput=$("$base"/scripts/connect_sshfs.sh "${name}" "${remoteHost}" "${remotePath}" "${localPath}" "${fuseOpts}")
      resultCode=$?

      echo "$resultOutput"

      case "$resultCode" in
        "0" )
          break
        ;;
        $EXIT_CODE_SSH_UNKNOWN_HOST ) # EXIT_CODE_SSH_UNKNOWN_HOST
          "$base"/scripts/onUnknownHost.sh "$remoteHost"
        ;;
        $EXIT_CODE_NO_USERNAME|$EXIT_CODE_NO_PASSWORD|$EXIT_CODE_SSH_PROBE_FAILED_PERMISSION_DENIED ) # username or password is empty or bad
          "$base"/scripts/onCredentialsProblem.sh "$name" "$remoteHost"
        ;;
        * )
          if "$base"/scripts/onGenericError.sh "$name" "$remoteHost" "$resultOutput"
          then
            echo "One more try requested..."
          else
            break
          fi
        ;;
      esac

      echo "Retrying connect..."
    done
  else
    "${base}"/scripts/connect_sshfs.sh "${name}" "${remoteHost}" "${remotePath}" "${localPath}" "${fuseOpts}"
    resultCode=$?
  fi

  return $resultCode
}

function disconnect {
  "${base}"/scripts/disconnect_sshfs.sh "${name}" "${localPath}"
}

function onExit1 {
  # kill all child processes
  pkill -P $$
}

trap onExit1 INT TERM EXIT


# main cycle
while :
do
  ping -f -i "${pollInterval}" "${remoteHost}" 2>/dev/null | {
  function ord {
    printf -v "${1?Missing Dest Variable}" "${3:-%d}" "'${2?Missing Char}"
  }

  function ord_hex {
    ord "${@:1:2}" "0x%x"
  }

  gotDot=0

  function process_buffer {
    case "$1" in
      # SPACE BACKSPACE - nothing
      "0x20 0x8" )
        return 0
      ;;

      "0x2e" ) # dot
        if (( gotDot == 0 )); then # if there was no dot previously then consume dot and remember it
          gotDot=1
          return 0
        else # if there was a dot already then this is NOACK
          echo "NOACK"
          return 0
        fi
      ;;

      "0x8" ) # BACKSPACE
        if (( gotDot = 1 )); then # if we are BACKSPACING dot previously remembered then it is OK
          gotDot=0
          echo "OK"
          return 0
        fi
      ;;

      "0x45" ) # E = general failure
        echo "ERR"
        return 0
      ;;
    esac

    return 1
  }

  scanbuffer=

  while IFS= read -r -n1 c
  do
    #echo "${c}" >> /tmp/output.log
    ord_hex code "${c}"
    if [ -z "$scanbuffer" ]
    then
        scanbuffer="${code}"
    else
        scanbuffer="${scanbuffer} ${code}"
    fi

    #echo "${scanbuffer}"
    if process_buffer "${scanbuffer}"
    then
       scanbuffer=
    fi

    if [ ${#scanbuffer} -ge 32 ]
    then
       echo "$scanbuffer"
       scanbuffer=
    fi
  done
  } | {
    processingAllowed=1

    function gracefulExit {
      processingAllowed=0
      disconnect
    }

    function onExit {
      gracefulExit
    }

    trap onExit INT TERM EXIT

    dotColumnIndex=1
    function printHeartBeat {
      printf "$1"
      if (( dotColumnIndex >= 60 )); then
        println
      else
        (( dotColumnIndex++ ))
      fi
    }

    function println {
      dotColumnIndex=1
      printf "\n"
    }

    positivesToGo="${positiveThreshold}"
    negativesToGo="${negativeThreshold}"
    lastActionTaken=-1

    while IFS= read line
    do
      if (( processingAllowed != 1 )); then
        echo "Processing not allowed..."
        continue
      fi

      case "${line}" in
        OK )
          printHeartBeat "."

          if (( positivesToGo >= 0 && (lastActionTaken == 0 || lastActionTaken == -1) )); then
            if (( positivesToGo > 0 )); then
               printf "${positivesToGo}"
            fi
            (( positivesToGo-- ))
          fi

          if (( positivesToGo == 0 && (lastActionTaken == 0 || lastActionTaken == -1) )); then
            printf '+>\n'
            if connect ; then
              lastActionTaken=1
              printf '\n<+'
            else
              exitCode=$?
              echo "Positive trigger failed: $exitCode"
              exit $exitCode
            fi
          fi

          negativesToGo="${negativeThreshold}"
        ;;
        NOACK|ERR )
          printHeartBeat "x"

          if (( negativesToGo >= 0 && (lastActionTaken == 1 || lastActionTaken == -1) )); then
            if (( negativesToGo > 0 )); then
               printf "${negativesToGo}"
            fi
            (( negativesToGo-- ))
          fi

          if (( negativesToGo == 0 && (lastActionTaken == 1 || lastActionTaken == -1) )); then
            printf 'X>\n'
            if disconnect ; then
              lastActionTaken=0
              printf '\n<X'
            else
              echo "Negative trigger failed: $?"
              exit 2
            fi
          fi

          positivesToGo="${positiveThreshold}"
        ;;
        * )
          echo "DEBUG: ${line}"
        ;;
      esac
    done
  }

  status="$PIPESTATUS"
  if [ "$status" != "2" ]; then # 2 is retrun code of ping when it fails to start pinging remoe host
     echo "EXIT: $status"
     exit $status
  else
    printf 'X'
  fi

  sleep "${pollInterval}"
done
