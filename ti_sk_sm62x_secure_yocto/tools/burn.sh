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

PFX=deploy-ti/images/am62xx-evm
# The .wic file's compressed, uncompress it
WICFILE=${PFX}/core-image-minimal-am62xx-evm.rootfs.wic
rm -f ${WICFILE} || true
runcmd "xz -dk ${WICFILE}.xz"
ls -lh ${WICFILE}
runcmd "fdisk -l ${WICFILE}"

echo "Proceed? SDcard * /dev/sda * ready?

*** NOTE ***

Assuming that /dev/sda is the correct disk to write to.
CONFIRM before going ahead please
"
read
runcmd "sync ; sudo umount /dev/sda[123] || true"
runcmd "sync ; time sudo dd if=${WICFILE} of=/dev/sda bs=4M conv=fsync"

echo "done, unmounting..."
runcmd "sync ; sudo umount /dev/sda[123] ; sync"
