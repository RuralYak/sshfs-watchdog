#!/bin/bash
echo "sshfs-wd-create-systemd-service.sh start"

base=$(readlink -f $(dirname "$0")/..)
source "$base/scripts/commons.sh"

suffix="${1:-instance}"
serviceUser="$2"
serviceConfigDir="${3:-$configDir}"
sshfswd=$(readlink -f "$base/sshfs-wd.sh")

echo "Service suffix is: $suffix"
echo "Service config dir is: $serviceConfigDir"

if [ -z "$serviceUser" ]; then
  read -e -p "Enter user name for service to run on behalf of: " -i "$user" serviceUser
fi

serviceFileName="sshfs-wd-$suffix.service"
targetFile="/etc/systemd/system/$serviceFileName"

if sudo cp "$base/systemd-service/sshfs-wd.service" "$targetFile" && \
  sudo sed -i.bak "s~#CONFIG_DIR#~$serviceConfigDir~g" "$targetFile" && \
  sudo sed -i.bak "s~#SSFS_WD_SCRIPT#~$sshfswd~g" "$targetFile" && \
  sudo sed -i.bak "s~#SUFFIX#~$suffix~g" "$targetFile" && \
  sudo sed -i.bak "s~#USER#~$serviceUser~g" "$targetFile" && \
  sudo rm -f "$targetFile.bak"
then
  echo "New file has been created successfully: $targetFile"

  sudo systemctl daemon-reload
  sudo systemctl enable "$serviceFileName"
  #systemctl start "$serviceFileName"
  echo "You can now start service: sudo systemctl start $serviceFileName"
else
  echo "Failed to create and process $targetFile"
fi

if [ "$CREDENTIALS_ADAPTER" == "gnomeKeychain" ]; then
  echo "WARNING: your config file (or its absence) tells sshfs to use gnomeKeychain backend for keys which is not supported in for services"
  writeDefaultConfig="Y"
  read -e -p "Would you like to write default config with supported key backed? [Y/n]: " -i "$writeDefaultConfig" writeDefaultConfig

  if mkdir -p "$configDir"
  then
    echo "Config dif created: $configDir"
  else
    echo "Error creating $configDir"
    exit 1
  fi

  if [ "$writeDefaultConfig" == "Y" ] || [ "$writeDefaultConfig" == "y" ]; then
    createOrModifyKeyValue "$configFile" "interactive" "0"
    createOrModifyKeyValue "$configFile" "SSHFS_WD_CREDENTIALS_ADAPTER" "flatFiles"
  fi
fi

echo "sshfs-wd-create-systemd-service.sh end"
