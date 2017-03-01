#/bin/bash
echo ">> disconnect_sshfs starts"

base=$(readlink -f $(dirname "$0"))
source "$base/commons.sh"

taskName="$1"
localFolder="$2"

# killing old sshfs daemon
killCycles=0
killMaxCycles=15
thereWasADaemon=0

while :
do
  sshfspid=$(getSSHFSpids "$user" "$localFolder")

  if [ ! -z "${sshfspid}" ]; then
    thereWasADaemon=1

    if (( killCycles == 0 )); then
      if kill -SIGTERM "${sshfspid}"
      then
        echo "SIGTERM signal has been sent to daemon ${sshfspid} for user $user and local folder $localPath"
      else
        echo "ERROR: Failed to send SIGTERM signal to ${sshfspid} for user $user and local folder $localPath"
      fi
    fi
  else
    break
  fi

  if (( killCycles > killMaxCycles )); then
    echo "Its been too much time to wait for sshfs to terminate"
    exit $EXIT_CODE_SSHFS_TERMINATION_TIMEOUT
  fi

  (( killCycles++ ))

  sleep 1
done

# cleaning up mountpoint
cleanupFuseLocalMountPoint "${localFolder}"

if (( thereWasADaemon == 1 )); then
  userInfo "$taskName" "${taskName} has been disconnected" network-wired-disconnected
fi

echo "<< disconnect_sshfs ends"
