#!/bin/bash

export base=$(readlink -f $(dirname "$0"))
source "$base/scripts/commons.sh"

name="$1"
remoteHost="$2"
login="$3"
password="$4"
remotePath="$5"
localPath="$6"

if [ -z "$name" ]; then
  read -e -p "Enter connection name: " name
fi

configFile="$connectionConfigDir/$name.config"

if [ -f "$configFile" ]; then
  echo "WARNING: Configuration file $configFile already exists. It will be replaced."
fi

if [ -z "$remoteHost" ]
then
  read -e -p "Enter remote ssh server DNS name or IP address: " remoteHost
fi

if [ -z "$remotePath" ]
then
  read -e -p "Enter remote path: " -i "/" remotePath
fi

if [ -z "$login" ]; then
  user=$(whoami)
  read -e -p "Enter user name for connection to $remoteHost: " -i "$user" login
fi

if [ -z "$password" ]; then
  read -e -s -p "Enter password for connection to $remoteHost: " password
  echo
fi

if [ -z "$localPath" ]
then
  read -e -p "Enter local path (mount point): " -i "~/mnt/$name" localPath
fi

echo "Adding $remoteHost to known hosts..."
addHostToKnown "$remoteHost"

# init credential storage
echo "Init credential storage..."
if credentialStorage_init; then
  echo "...done"
else
  echo "FAILED with code: $?"
  exit $EXIT_CODE_CREDENTIAL_STORAGE_FAILED
fi

echo "Storing credentials..."
credentials_setLogin "$name" "$login"
credentials_setPassword "$name" "$password"

if mkdir -p "$connectionConfigDir"
then
  echo "Writing config file to $configFile ..."
  echo "name=$name" >"$configFile"
  echo "remoteHost=$remoteHost" >>"$configFile"
  echo "remotePath=$remotePath" >>"$configFile"
  echo "localPath=$localPath" >>"$configFile"
else
  exit 1
fi
