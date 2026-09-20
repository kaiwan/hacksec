#!/bin/bash

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
name=$(basename $0)

die() { 
echo >&2 "FATAL:${name}: $" ; exit 1 
} 
warn() { 
echo >&2 "WARNING:${name}: $" 
}
# runcmd
# Parameters
#   $1 ... : params are the command to run
runcmd() { 
[[ $# -eq 0 ]] && return 
echo "$@" 
eval "$@" 
}

# The .wic file's compressed, uncompress it
WICFILE=core-image-minimal-am62xx-evm.rootfs.wic
rm -f deploy-ti/images/am62xx-evm/${WICFILE} || true
runcmd "xz -dk deploy-ti/images/am62xx-evm/${WICFILE}.xz"
ls -lh deploy-ti/images/am62xx-evm/${WICFILE}

echo "Proceed? SDcard * /dev/sda * ready? " ; read
runcmd "sync ; sudo umount /dev/sda[12] || true"
runcmd "sync ; time sudo dd if=deploy-ti/images/am62xx-evm/${WICFILE} of=/dev/sda bs=4M conv=fsync"

echo "done, unmounting..."
runcmd "sync ; sudo umount /dev/sda[12] ; sync"
