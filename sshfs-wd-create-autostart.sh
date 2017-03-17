#!/bin/bash

export base=$(readlink -f $(dirname "$0"))
autostartDir="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"

for autoFile in $autostartDir/*.desktop
do
  if [ ! -f "$autoFile" ]; then
    continue
  fi

  if [ ! -z $(cat "$autoFile" | grep "sshfs-wd.sh") ]; then
    echo "Old autostart file found: $autoFile"
    if rm -f "$autoFile"
    then
      echo "Old file deleted."
    else
      echo "WARNING: Unable to delete old file: $autoFile"
    fi
  fi
done

newAutoFile="$autostartDir/sshfs-wd-autostart.desktop"

if mkdir -p "$autostartDir"
then
  echo "[Desktop Entry]" >"$newAutoFile"
  echo "Type=Application" >>"$newAutoFile"
  echo "Name=Autostart configured SSFS watchdogs" >>"$newAutoFile"
  echo "Exec=$base/sshfs-wd.sh" >>"$newAutoFile"
  echo "Hidden=false" >>"$newAutoFile"

  echo "New file has been created: $newAutoFile"
else
  exit 1
fi
