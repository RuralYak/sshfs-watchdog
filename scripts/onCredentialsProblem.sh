#!/bin/bash

echo ">> onCredentialsProblem.sh"

base=$(readlink -f $(dirname "$0"))
source "$base/commons.sh"

taskName="$1"
remoteHost="$2"

yad --notification --image="important" --text="Credentials needed for $remoteHost"

# ask for username
login0=$(getLogin "$taskName")

while :
do
  echo "Asking for login..."

  login=$(yad \
    --class="GSu" \
    --title="Login for $taskName" \
    --text="Enter login for $taskName:" \
    --window-icon="dialog-password" \
    --image="dialog-password" \
    --width=500 \
    --entry \
    --center \
    --fixed \
    --sticky \
    --button="gtk-ok:0" \
    --button="gtk-close:1" \
    --entry-text "$login0" \
  )
  loginFormResult=$?

  if [ "$loginFormResult" != "0" ]; then
    echo "User requested cancel"
    exit 1
  fi

  echo "Entered login was: $login"

  if [ -z "$login" ]; then
    continue
  fi

  if [ "$login" != "$login0" ]; then
    setLogin "$taskName" "$login"
  fi
  break
done

# password
password=$(getPassword "$taskName")

fakePassword=
if [ ! -z "$password" ]; then
  fakePassword="[fake password]"
fi

echo "Asking for password..."

password=$(yad \
  --class="GSu" \
  --title="Password for $taskName" \
  --text="Enter password for $login@$remoteHost:" \
  --window-icon="dialog-password" \
  --image="dialog-password" \
  --width=500 \
  --entry \
  --hide-text \
  --center \
  --fixed \
  --sticky \
  --button="gtk-ok:0" \
  --button="gtk-close:1" \
  --entry-text "$fakePassword" \
)

if [ $? != "0" ]; then
  echo "User requested cancel"
  exit 1
fi

if [ "$password" != "$fakePassword" ]; then
  setPassword "$taskName" "$password"
fi

echo "<< onCredentialsProblem.sh"
