#!/bin/bash

export base=$(readlink -f $(dirname "$0"))
source "$base/scripts/commons.sh"

name="$1"

configFile="$connectionConfigDir/$name.config"

if [ ! -f "$configFile" ]; then
  echo "No such config file : $configFile"
fi

# init credential storage
echo "Init credential storage..."
if credentialStorage_init; then
  echo "...done"
else
  echo "FAILED with code: $?"
  exit $EXIT_CODE_CREDENTIAL_STORAGE_FAILED
fi

credentials_removeLogin "$name"
credentials_removePassword "$name"

rm -f "$configFile"
