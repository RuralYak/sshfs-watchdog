#!/bin/bash

base=$(readlink -f $(dirname "$0"))

"$base"/sshfs-wd.sh stop
