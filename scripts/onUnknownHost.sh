#!/bin/bash

#base=$(readlink -f $(dirname "$0"))
source "$base/scripts/commons.sh"

remoteHost="$1"

yad --notification --image="important" --text="Remote host $remoteHost is unknown SSH host."
if yad --width=500 \
  --center \
  --fixed \
  --sticky \
  --window-icon="important" \
  --image="important" \
  --button="gtk-ok:0" \
  --button="gtk-close:1" \
  --title="SSH signature is unknown" \
  --text="Remote host signature for $remoteHost is unknown. Would you like to add the signature to known hosts ?"
then
  echo "Adding fingerprint for $remoteHost"
  # resetting remote side fingerprint
  addHostToKnown "$remoteHost"
fi
