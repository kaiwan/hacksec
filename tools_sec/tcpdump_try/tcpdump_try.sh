#!/bin/bash
# (c) Kaiwan NB, kaiwanTECH

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

die()
{
echo >&2 "FATAL: $*"
exit 1
}

# runcmd
# Parameters
#   $1 ... : params are the command to run
runcmd()
{
	[ $# -eq 0 ] && return
	echo "$@"
	eval "$@"
}

# generate some n/w traffic
download_a_file()
{
  local URL=https://www.kernel.org/pub/linux/kernel/v7.x/linux-7.0.8.tar.xz
  timeout ${TIMEOUT} wget ${URL} -O /tmp/$(basename ${URL})
  echo "-- wget killed ($?)"
}


#-- 'main'
TIMEOUT=15s
download_a_file &

# let's capture web traffic (ports 80 or 443) on n/w interface INTF
INTF=wlo1  # ADJUST as required
TIMEOUT=$((TIMEOUT+3))
runcmd "sudo timeout ${TIMEOUT} tcpdump -i ${INTF} -w web_traffic.pcap port 80 or port 443"
# Now examine the .pcap file in Wireshark
