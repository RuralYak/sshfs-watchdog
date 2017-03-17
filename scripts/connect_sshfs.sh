#/bin/bash

echo ">> connect_sshfs starts"

source "$base/scripts/commons.sh"

taskName="$1"
remoteName="$2"
remotePath="$3"
localFolder="$4"
options="$5"


# init credential storage
echo "Init credential storage..."
if credentialStorage_init; then
  echo "...done"
else
  echo "FAILED with code: $?"
  exit $EXIT_CODE_CREDENTIAL_STORAGE_FAILED
fi

# login
if credentials_isLoginExists "$taskName"
then
  connectLogin=$(credentials_getLogin "$taskName")
  echo "Using login stored to keyring: ${connectLogin}"
else
  userError "$taskName" "No login found for $taskName." $EXIT_CODE_NO_USERNAME
fi

# password
if credentials_isPasswordExists "$taskName"
then
  connectPassword=$(credentials_getPassword "$taskName")
  echo "Using password stored to keyring"
else
  userError "$taskName" "No password found for ${remoteName}." $EXIT_CODE_NO_PASSWORD
fi

# check sshfs daemon already running
sshfspid=$(getSSHFSpids "$user" "$localFolder")
if [ ! -z "${sshfspid}" ]; then
  userError "$taskName" "Another sshfs daemon is running for a particular user, remote and local paths. Kill it first." $EXIT_CODE_SSHFS_DAEMON_ALREADY_RUNNING
fi

# check local mount point
localMountpointProbingResult=$(ls -A ${localFolder} 2>&1)
if [ $? != "0" ] ; then
  echo "local mountpoint probing result: ${localMountpointProbingResult}"

  case "${localMountpointProbingResult}" in
    *Transport\ endpoint\ is\ not\ connected* | *Input/output\ error* )
      echo "Trying to cleanup local mountpoint..."
      if cleanupFuseLocalMountPoint "${localFolder}"
      then
        echo "Seems ok now"
      else
        userError "$taskName" "Found problem with local mountpoint: ${localFolder} and can not recover it" $EXIT_CODE_LOCAL_MOUNTPOINT_PROBLEM
      fi
    ;;

    *No\ such\ file\ or\ directory* )
      if mkdir -p "${localFolder}"; then
        echo "Local folder created: ${localFolder}"
      else
        userError "$taskName" "Unable to create local mount point: ${localFolder}" $EXIT_CODE_LOCAL_MOUNTPOINT_PROBLEM
      fi
    ;;

    * )
      userError "$taskName" "Unrecoverable error of local mountpoint: ${localFolder}" $EXIT_CODE_LOCAL_MOUNTPOINT_PROBLEM
    ;;
  esac
else
  echo "local mountpoint content: $localMountpointProbingResult"
fi

# check if remote host is known
if isHostKnown "$remoteName"
then
  echo "Remote host $remoteName is known"
else
  userError "$taskName" "Remote host $remoteName seems to be unknown" $EXIT_CODE_SSH_UNKNOWN_HOST
fi

# probe remote host for sftp connection
echo "Probing for remote sftp..."
probe=$(echo bye | sshpass -p "$connectPassword" ssh -o ConnectTimeout=10 $connectLogin@$remoteName -s "sftp" 2>&1)
probeResult=$?

case "$probeResult" in
  0 )
    echo "Probe successful. We are good to go."
  ;;

  5 )
    userError "$taskName" "$probe" $EXIT_CODE_SSH_PROBE_FAILED_PERMISSION_DENIED
  ;;

  * )
    echo "Probe failed with code $probeResult : $probe"
    userError "$taskName" "Remote server probe failed: $probe" $EXIT_CODE_SSH_PROBE_FAILED_UNKNOWN
  ;;
esac


# create temporary pipe for communication with subshell
commPipeDir="/tmp/sshfs-wd-${user}"
if mkdir -p "${commPipeDir}"; then
  echo "Temporary folder for pipe: ${commPipeDir}"
else
  userError "$taskName" "Can not create folder ${commPipeDir}" $EXIT_CODE_TEMPORARY_PIPE_PROBLEM
fi

while :
do
  commPipeName=$(mktemp -u XXXXXXXXX.pipe)
  commPipe="${commPipeDir}/${commPipeName}"
  if [[ ! -p "${commPipe}" ]]; then
    if mkfifo "${commPipe}"; then
      echo "comm pipe created: ${commPipe}"
      trap "echo 'Removing comm pipe: ${commPipe}'; rm -f ${commPipe}" EXIT
      break
    else
      userError "$taskName" "Unable to create comm pipe ${commPipe}" $EXIT_CODE_TEMPORARY_PIPE_PROBLEM
    fi
  fi

  sleep 1
done

if [ -z "$options" ]
then
    options="password_stdin"
else
    options="$options,password_stdin"
fi

connectionString="${connectLogin}@${remoteName}:${remotePath}"

# run subshell
( echo "doing: sshfs -o ${options} ${connectionString} ${localFolder}"

sshfsOutput=$(echo "${connectPassword}" | sshfs -o "${options}" "${connectionString}" "${localFolder}" 2>&1)
sshfsCode=$?

if [ "$sshfsCode" == "0" ] ; then
  echo "sshfs seems to be started ok"
  echo "1" >"${commPipe}"
else
  echo "sshfs failed to start"

  if [ ! -z "${sshfsOutput}" ]; then
    echo "${sshfsOutput}" >"${commPipe}"
  else
    echo "Call to sshfs was unsuccessful" >"${commPipe}"
  fi
fi
)&

# wait for subshell
echo "waiting for response..."
subshellResponse=
read -t 10 subshellResponse <"${commPipe}"

if [[ "${subshellResponse}" == "1" ]]; then
  userInfo "$taskName" "Remote sshfs at ${connectionString} has been mounted to ${localFolder} successfuly."
else
  userError "$taskName" "Unable start sshfs daemon: ${subshellResponse}" $EXIT_CODE_SSHFS_START_ERROR
fi

echo "<< connect_sshfs ends"
