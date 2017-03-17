
#local base=$(readlink -f $(dirname "$0"))
source "$base/scripts/credentialStorages/credentialStorage.intf"

flatFilesDir=~/.passwords

# ---- implementation of to credentialStorage.intf

function credentialStorage_init {
  mkdir -p "$flatFilesDir"
  echo "flat files dir: $flatFilesDir"
}

function credentials_isLoginExists {
  local unitName="$1"

  test -f "$flatFilesDir/$unitName.login.txt"
}

function credentials_getLogin {
  local unitName="$1"

  cat "$flatFilesDir/$unitName.login.txt"
}

function credentials_setLogin {
  local unitName="$1"
  login="$2"

  echo "$login" >"$flatFilesDir/$unitName.login.txt"
}

function credentials_removeLogin {
  local unitName="$1"
  rm -f "$flatFilesDir/$unitName.login.txt"
}

function credentials_isPasswordExists {
  local unitName="$1"
  test -f "$flatFilesDir/$unitName.password.txt"
}

function credentials_getPassword {
  local unitName="$1"

  cat "$flatFilesDir/$unitName.password.txt"
}

function credentials_setPassword {
  local unitName="$1"
  local password="$2"

  echo "$password" >"$flatFilesDir/$unitName.password.txt"
}

function credentials_removePassword {
  local unitName="$1"
  rm -f "$flatFilesDir/$unitName.password.txt"
}
