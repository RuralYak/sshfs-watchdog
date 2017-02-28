
# connect exit codes
EXIT_CODE_NO_USERNAME=100
EXIT_CODE_NO_PASSWORD=101
EXIT_CODE_SSHFS_DAEMON_ALREADY_RUNNING=110
EXIT_CODE_LOCAL_MOUNTPOINT_PROBLEM=120
EXIT_CODE_TEMPORARY_PIPE_PROBLEM=130
EXIT_CODE_SSHFS_START_ERROR=140
EXIT_CODE_SSH_UNKNOWN_HOST=150
EXIT_CODE_SSH_PROBE_FAILED_UNKNOWN=160
EXIT_CODE_SSH_PROBE_FAILED_PERMISSION_DENIED=161
EXIT_CODE_SSHFS_TERMINATION_TIMEOUT=170

KEYCHAIN_LOGIN_KEY="login"
KEYCHAIN_PASSWORD_KEY="password"

# globaly shared common variables
user=$(whoami)
configDir=~/.config/sshfs-wd

function debug {
  local file="/tmp/sshfs-wd-$user-debug.log"
  local string="$1"

  if [ -f "$file" ]; then
    echo "$string">>"$file"
  else
    echo "$string">"$file"
  fi
}

# keychain related routines
function isKeychainElementExists {
  local attribute="$1"
  local value="$2"

  if [ -f "$attribute.$value" ]; then # if stub exists
    return 0
  fi

  #debug "secret-tool lookup $attribute $value"
  secret-tool lookup "$attribute" "$value" 1>/dev/null
}

function getKeychainElement {
  local attribute="$1"
  local value="$2"

  if [ -f "$attribute.$value" ]; then # if stub exists
    cat "$attribute.$value"
    return $?
  fi

  secret-tool lookup "$attribute" "$value"
}

function setKeychainElement {
  local attribute="$1"
  local value="$2"
  local content="$3"

  if [ -f "$attribute.$value" ]; then # if stub exists
    echo "$content" > "$attribute.$value"
    return $?
  fi

  echo "$content" | secret-tool store --label="$attribute $value" "$attribute" "$value"
}

function removeKeychainElement {
  local attribute="$1"
  local value="$2"

  secret-tool clear "$attribute" "$value"
}

function isLoginExists {
  local unitName="$1"

  isKeychainElementExists "$unitName" "$KEYCHAIN_LOGIN_KEY"
}

function getLogin {
  local unitName="$1"
  getKeychainElement "$unitName" "$KEYCHAIN_LOGIN_KEY"
}

function setLogin {
  local unitName="$1"
  login="$2"

  setKeychainElement "$unitName" "$KEYCHAIN_LOGIN_KEY" "$login"
}

function removeLogin {
  local unitName="$1"
  removeKeychainElement "$unitName" "$KEYCHAIN_LOGIN_KEY"
}

function isPasswordExists {
  local unitName="$1"
  isKeychainElementExists "$unitName" "$KEYCHAIN_PASSWORD_KEY"
}

function getPassword {
  local unitName="$1"
  getKeychainElement "$unitName" "$KEYCHAIN_PASSWORD_KEY"
}

function setPassword {
  local unitName="$1"
  local password="$2"

  setKeychainElement "$unitName" "$KEYCHAIN_PASSWORD_KEY" "$password"
}

function removePassword {
  local unitName="$1"
  removeKeychainElement "$unitName" "$KEYCHAIN_PASSWORD_KEY"
}

# ssh related stuff
function addHostToKnown {
  local remoteHost="$1"

  ssh-keygen -R "$remoteHost"
  ssh-keyscan -H "$remoteHost" >>~/.ssh/known_hosts
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
  exit $2
}
