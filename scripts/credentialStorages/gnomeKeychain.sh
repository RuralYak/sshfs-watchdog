# imports
#local base=$(readlink -f $(dirname "$0"))
source "$base/scripts/credentialStorages/credentialStorage.intf"


# consts
KEYCHAIN_LOGIN_KEY="login"
KEYCHAIN_PASSWORD_KEY="password"


# ---- implementation of to credentialStorage.intf

function credentialStorage_init {
  echo "nothing" >/dev/null
}

function credentials_isLoginExists {
  local unitName="$1"

  isKeychainElementExists "$unitName" "$KEYCHAIN_LOGIN_KEY"
}

function credentials_getLogin {
  local unitName="$1"
  getKeychainElement "$unitName" "$KEYCHAIN_LOGIN_KEY"
}

function credentials_setLogin {
  local unitName="$1"
  login="$2"

  setKeychainElement "$unitName" "$KEYCHAIN_LOGIN_KEY" "$login"
}

function credentials_removeLogin {
  local unitName="$1"
  removeKeychainElement "$unitName" "$KEYCHAIN_LOGIN_KEY"
}

function credentials_isPasswordExists {
  local unitName="$1"
  isKeychainElementExists "$unitName" "$KEYCHAIN_PASSWORD_KEY"
}

function credentials_getPassword {
  local unitName="$1"
  getKeychainElement "$unitName" "$KEYCHAIN_PASSWORD_KEY"
}

function credentials_setPassword {
  local unitName="$1"
  local password="$2"

  setKeychainElement "$unitName" "$KEYCHAIN_PASSWORD_KEY" "$password"
}

function credentials_removePassword {
  local unitName="$1"
  removeKeychainElement "$unitName" "$KEYCHAIN_PASSWORD_KEY"
}

# --- aux routines

# keychain related routines
function isKeychainElementExists {
  local attribute="$1"
  local value="$2"

  secret-tool lookup "$attribute" "$value" 1>/dev/null
}

function getKeychainElement {
  local attribute="$1"
  local value="$2"

  secret-tool lookup "$attribute" "$value"
}

function setKeychainElement {
  local attribute="$1"
  local value="$2"
  local content="$3"

  echo "$content" | secret-tool store --label="$attribute $value" "$attribute" "$value"
}

function removeKeychainElement {
  local attribute="$1"
  local value="$2"

  secret-tool clear "$attribute" "$value"
}
