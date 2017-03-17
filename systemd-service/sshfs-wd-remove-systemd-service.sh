#!/bin/bash
echo "sshfs-wd-remove-systemd-service.sh start"

base=$(readlink -f $(dirname "$0"))
source "$base/../scripts/commons.sh"

suffix="${1:-instance}"

echo "Service suffix is: $suffix"

serviceFileName="sshfs-wd-$suffix.service"
targetFile="/etc/systemd/system/$serviceFileName"

sudo systemctl stop "$serviceFileName"
sudo systemctl disable "$serviceFileName"
sudo rm -f "$targetFile"

echo "sshfs-wd-remove-systemd-service.sh end"
