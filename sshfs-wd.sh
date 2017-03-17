#!/bin/bash
echo "sshfs-wd.sh start"

#base=$(readlink -f $(dirname "$0"))
#$(readlink -f $(dirname "$0"))/scripts/variables.sh
export base=$(readlink -f $(dirname "$0"))
source "$base/scripts/commons.sh"

command="$1"

if mkdir -p "$connectionConfigDir"; then
  echo "Using config dir: $connectionConfigDir"
else
  echo "Failed to create config dir: $connectionConfigDir"
  exit 1
fi

if ls $connectionConfigDir/*.config 1> /dev/null 2>&1; then
  echo "Some configs are in place..."
else
  echo "No configs found in config folder (*.config). Exiting..."
  exit 0
fi

# process configurations
for conf in "$connectionConfigDir"/*.config
do
  if [ ! -f "$conf" ]; then
    continue
  fi

  echo "Processing $conf"

  killCycles=0
  killMaxCycles=15
  while :
  do
    instancePids=$(getSshfsWdInstancePids "$user" "$conf")

    if [ ! -z "${instancePids}" ]; then
      if (( killCycles == 0 )); then
        if kill -SIGTERM $instancePids
        then
          echo "Sent SIGTERM to processes: ${instancePids}"
        else
          echo "Failed to send SIGTERM to processes: ${instancePids}"
          exit 1
        fi
      fi
    else
      break
    fi

    if (( killCycles > killMaxCycles )); then
      echo "We waited too much... processes appears to be stuck: ${instancePids}"
      exit 1
    fi

    echo "waiting ${killCycles} / ${killMaxCycles}"
    (( killCycles++ ))
    sleep 1
  done

  if [ "$command" == "stop" ]; then # if stop command is passed then no new instances should be launched
    continue
  fi

  configFileBasename=$(basename "$conf")
  # start watch dog instance
  ( "$base"/scripts/sshfs-wd-instance.sh "$conf" 2>&1

    if [ $? == "0" ] ; then
      echo "${configFileBasename} started"
    else
      echo "ERROR during startup ${configFileBasename}"
    fi
  ) >> "/tmp/sshfs_${user}_${configFileBasename}.log" &
done

echo "sshfs-wd.sh end"
