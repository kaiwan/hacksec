#!/bin/bash
# load_drv.sh
# Helper script to load the driver kernel module,
# also creating the device nodes as necessary.
# 
# Usage:
# load_drv.sh [-option] module ; where option is one of:
# 	-c :	create and load the device file DEV1
# 	-l :	only load the device module into the kernel
# 	--help: show this help screen
#
# * Author: Kaiwan N Billimoria <kaiwan@kaiwantech.com>
# * License: Dual MIT/GPL

# Configuration variables
DEV="/dev/mmap_baddrv"
PERMS="666"
MAJOR=10    # misc major

# Refresh the device nodes
function creat_dev() {
	echo "Creating device file $DEV .."

	# Get dynamic major
	# Assumption: the name of the driver is "$KMOD"
	MINOR=`grep ${KMOD} /proc/misc | awk '{print $1}'`
	if [ -z $MINOR ]; then
		echo "$0: Could not get misc minor number, aborting.."
		exit 1
	fi
	echo "$0: misc MINOR number is $MINOR"

	# remove any stale instances
	rm $DEV 2>/dev/null
	mknod -m$PERMS $DEV c $MAJOR $MINOR
	if [ $? -ne 0 ]; then
		echo "$DEV device creation mknod failure.."
	fi
}

function load_dev() { 
	/sbin/rmmod $KMOD 2>/dev/null	# in case it's already loaded

	/sbin/insmod $KMOD.ko || {
		echo "insmod failure.."
		exit 1
	}

	echo "Module $KMOD successfully inserted"
	echo "Looking up last 5 printk's with dmesg.."
	/bin/dmesg | tail -n5
}

function usage() {
	echo "Usage help:: \
 	$0 [-option] module ; 
 where option is one of:
 	-c :	load the driver and create the device file ${DEV}
 	-l :	only load the device module [module] into the kernel
 	--help: show this help screen
 and module is the filename of the module."
	exit 1
}

# main here

if [ "$(id -u)" != "0" ]; then
	echo "Requires root"
	exit 1
fi

if [ $# -ne 2 ]; then
	usage
fi
[[ "${2}" = *"."* ]] && {
  echo "Usage: ${name} name-of-kernel-module-file ONLY (do NOT put any extension or '.')"
  exit 1
}

KMOD=$2
if [ ! -e $KMOD.ko ]; then
	echo "$0: $KMOD.ko not a valid file/pathname."
	exit 1 
fi

case "$1" in
   --help) 
	usage
	;;
   -c)
	echo "Loading module and creating device files for device $DEV now.."
	load_dev 
	creat_dev 
	;;	# falls thru to the load..
   -l)
	echo "Loading device $DEV now.."
	load_dev 
	exit 0
	;;
   *)
	usage
	;;
esac
exit 0
