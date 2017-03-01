#!/bin/bash

name="$1"
remoteHost="$2"
errorText="$3"

yad --notification --image="important" --text="$name error"
echo "$errorText" | yad --width=500 \
  --height=500 \
  --center \
  --sticky \
  --window-icon="important" \
  --image="important" \
  --button="gtk-ok:0" \
  --button="gtk-close:1" \
  --title="$name error" \
  --text-info \
  --text="Would you like to try again ?"
