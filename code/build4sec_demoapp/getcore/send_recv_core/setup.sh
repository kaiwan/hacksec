#!/bin/bash
# Setup the core_pattern pseudo-file for sending our core dumps over the
# network [part of the send-recv-corefile project].
# (c) 2018 kaiwanTECH
name=$(basename $0)

[ $(id -u) -ne 0 ] && {
  echo "${name} : must be root."
  exit 1
}
[ $# -ne 1 ] && {
  echo "Usage: ${name} target-IP-addr"
  exit 1
}
ulimit -c unlimited
echo "| $(pwd)/send_core_dbg $1" > /proc/sys/kernel/core_pattern || exit 1
echo "Pseudo-file /proc/sys/kernel/core_pattern is set to:
$(cat /proc/sys/kernel/core_pattern)"
exit 0
