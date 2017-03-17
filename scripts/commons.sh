
#base=$(readlink -f $(dirname "$0"))

# connect exit codes
EXIT_CODE_NO_USERNAME=100
EXIT_CODE_NO_PASSWORD=101
EXIT_CODE_CREDENTIAL_STORAGE_FAILED=103
EXIT_CODE_SSHFS_DAEMON_ALREADY_RUNNING=110
EXIT_CODE_LOCAL_MOUNTPOINT_PROBLEM=120
EXIT_CODE_TEMPORARY_PIPE_PROBLEM=130
EXIT_CODE_SSHFS_START_ERROR=140
EXIT_CODE_SSH_UNKNOWN_HOST=150
EXIT_CODE_SSH_PROBE_FAILED_UNKNOWN=160
EXIT_CODE_SSH_PROBE_FAILED_PERMISSION_DENIED=161
EXIT_CODE_SSHFS_TERMINATION_TIMEOUT=170

function die {
  local frame=0
  while caller $frame; do
    ((frame++));
  done
  echo "$*"
  exit 1
}

# globaly shared common variables
user=$(whoami)
home=~
configDir="${SSHFS_WD_CONFIG_DIR:-$home/.config/sshfs-wd}"
configFile="$configDir/sshfs-wd.config"
connectionConfigDir="$configDir/connections"

# load global config file
if [ -f "$configFile" ]; then
  echo "Sourcing config file: $configFile"
  source "$configFile"
else
  echo "No global config file. Using defaults."
fi

# load credentials adapter
CREDENTIALS_ADAPTER="${SSHFS_WD_CREDENTIALS_ADAPTER:-gnomeKeychain}"
source "$base/scripts/credentialStorages/$CREDENTIALS_ADAPTER.sh"

function debug {
  local file="/tmp/sshfs-wd-$user-debug.log"
  local string="$1"

  if [ -f "$file" ]; then
    echo "$string">>"$file"
  else
    echo "$string">"$file"
  fi
}

# ssh related stuff
function addHostToKnown {
  local remoteHost="$1"

  ssh-keygen -R "$remoteHost"
  ssh-keyscan -H "$remoteHost" >>"$home/.ssh/known_hosts"
}

function isHostKnown {
  local remoteHost="$1"
  ssh-keygen -F "$remoteHost" >/dev/null
}

function cleanupFuseLocalMountPoint {
  local localFolder="$1"
  fusermount -uz "$localFolder" 2>&1
}

function getSSHFSpids {
  local user="$1"
  local mountpoint="$2"

  ps -C sshfs -f | grep "$user.*$mountpoint" | grep -v grep | awk '{print $2}' | tr '\n' ' '
}

function getSshfsWdInstancePids {
  local user="$1"
  local conf="$2"

  ps -aux | grep "$user.*sshfs-wd-instance.sh.*$conf" | grep -v grep | awk '{print $2}' | tr '\n' ' '
}

# ------------------------------------------------------------------------------
# user interaction

function userInfo {
  local title="$1"
  local message="$2"
  local icon="${3:-gnome-fs-ssh}"

  echo "$message"
  notify-send "--icon=$icon" --urgency=normal "$title" "$message"
}

function userError {
  local title="$1"
  local message="$2"
  local exitCode="$3"
  local icon="${4:-error}"

  echo "$message"
  notify-send "--icon=$icon" --urgency=critical "$title" "$message"
  exit $exitCode
}

# ------------------------------------------------------------------------------
# config file related

function createOrModifyKeyValue {
  local CONFIG_FILE="$1"
  local TARGET_KEY="$2"
  local REPLACEMENT_VALUE="$3"

  if [ -f "$CONFIG_FILE" ]; then
    if grep -q "^[ ^I]*$TARGET_KEY=" "$CONFIG_FILE"; then
     sed -i -e "s^A^\\([ ^I]*$TARGET_KEY=\\).*$^A\\1$REPLACEMENT_VALUE^A" "$CONFIG_FILE"
    else
       echo "$TARGET_KEY=\"$REPLACEMENT_VALUE\"" >>"$CONFIG_FILE"
    fi
  else
    echo "$TARGET_KEY=\"$REPLACEMENT_VALUE\"" >"$CONFIG_FILE"
  fi
}
