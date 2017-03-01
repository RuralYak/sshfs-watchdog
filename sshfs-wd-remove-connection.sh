#!/bin/bash

base=$(readlink -f $(dirname "$0"))
source "$base/scripts/commons.sh"

name="$1"

configFile="$configDir/$name.config"

if [ ! -f "$configFile" ]; then
  echo "No such config file : $configFile"
fi

removeLogin "$name"
removePassword "$name"

rm -f "$configFile"
