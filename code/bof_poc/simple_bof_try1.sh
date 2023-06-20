#!/bin/bash
# simple_bof_try1.sh
# Part of my 'hacksec' github repo:
# https://github.com/kaiwan/hacksec

# Turn on unofficial Bash 'strict mode'! V useful
# "Convert many kinds of hidden, intermittent, or subtle bugs into immediate, glaringly obvious errors"
# ref: http://redsymbol.net/articles/unofficial-bash-strict-mode/ 
set -euo pipefail

name=$(basename "$0")
CHKSEC=../../tools_sec/checksec.sh/checksec
RUN_CHKSEC=1

# wrapper over checksec script
checkit()
{
[[ $# -ne 1 ]] && return

# the readelf check below isn't reliable??
#echo -n "
#$1 : Is Stack Guarded? "
#readelf -s ${1} |grep -q __stack_chk_guard && echo "Yes!" || echo "Nope"

[[ ${RUN_CHKSEC} -eq 1 ]] && {
  echo "checksec.sh:"
  ${CHKSEC} --file="${1}"
}
}

#------------ t e s t _ b o f ----------------------------------
# Parameters:
#  $1 : pathname of PUT
#  $2 : message to print
test_bof()
{
[[ $# -ne 2 ]] && return
local PUT=${1}         # Program Under Test
[[ ! -f ${PUT} ]] && {
  echo "${name}: binary executable \"${PUT}\" missing.."
  return
}

echo "
-----------------------------------------------------------------------
${2}
$(ls -lh ${PUT})
-----------------------------------------------------------------------"
checkit ${PUT}

local re
echo -n "Run BOF on ${PUT}? [Y/n] "
read re
[[ "${re}" = "n" || "${re}" = "N" ]] && return

set +e # turn off 'strict fail'
# Run the PUT overflowing the stack buffer (it's 12 bytes, send 20)
perl -e 'print "A"x12 . "B"x4 . "C"x4' | ./${PUT}

# Our program ${PUT} will terminate with an exit status:
# Exit codes ref: https://www.geeksforgeeks.org/exit-codes-in-c-c-with-examples/
local stat=$?
set -e # turn on 'strict fail'
echo "stat=${stat}"
case ${stat} in
   0) echo "*** All OK ***" ;;
 127) echo "!!! file not found error !!!" ;;
 132) echo "!!! terminated via SIGILL !!!" ;;
 133) echo "!!! terminated via SIGTRAP (poss failed assertion) !!!" ;;
 134) echo "!!! aborted via SIGABRT !!!" ;;
 137) echo "!!! terminated: high memory usage !!!" ;;
 138) echo "!!! aborted via SIGBUS !!!" ;;
 139) echo "!!! terminated via SIGSEGV (poss memory bug) !!!" ;;
 158|152) echo "!!! terminated via SIGXCPU !!!" ;;
 159|153) echo "!!! terminated via SIGXFSZ !!!" ;;
 *) echo "!!! terminated with exit status ${stat} !!!" ;;
esac
}

askfornext()
{
  read -p "<< Press [Enter] to continue, ^C to abort... >>"
}

ASLR_reset()
{
 ASLR=$(cat /proc/sys/kernel/randomize_va_space)
 [[ ${ASLR} -eq 0 ]] && {
	echo "Resetting ASLR to ON (2) now"
	sudo sh -c "echo 2 > /proc/sys/kernel/randomize_va_space"
 }
}


## 'main'
if [[ ! -f ${CHKSEC} ]] ; then
echo "${name}: Warning! shell script \"${CHKSEC}\" missing..(will skip)"
  RUN_CHKSEC=0
elif [[ ${RUN_CHKSEC} -eq 1 ]] ; then
  echo "checksec: FYI, the meaning of the columns:
 'Fortified'   = # of functions that are actually fortified
 'Fortifiable' = # of functions that can be fortified"
fi

# Ensure that ASLR is Off
aslr=$(cat /proc/sys/kernel/randomize_va_space)
[[ ${aslr} -ne 0 ]] && {
	echo "*** WARNING ***
ASLR is ON; prg may not work as expected!
Will attempt to turn it OFF now ...
"
sudo sh -c "echo 0 > /proc/sys/kernel/randomize_va_space"
aslr=$(cat /proc/sys/kernel/randomize_va_space)
[[ ${aslr} -ne 0 ]] && echo "*** WARNING *** ASLR still ON" || echo "Ok, it's now Off"
}

# PUT = Program Under Test
i=1
PUT=./bof_vuln_reg
test_bof ${PUT} "Test #$i : program built with system's default GCC flags"
askfornext

#let i=i+1
#PUT=./bof_vuln_reg_stripped
#test_bof ${PUT} "Test #2 : program built with system's default GCC flags and stripped"
#askfornext

let i=i+1
PUT=./bof_vuln_fortified
test_bof ${PUT} "Test #$i : program built with system's GCC with fortification ON"
askfornext

let i=i+1
PUT=./bof_vuln_stackprot
test_bof ${PUT} "Test #$i : program built with system's GCC with stack prot ON"
askfornext

let i=i+1
PUT=./bof_vuln_strongprot
test_bof ${PUT} "Test #$i : program built with system's GCC with 'STRONG' (all) protections ON"
askfornext

let i=i+1
PUT=./bof_vuln_lessprot
test_bof ${PUT} "Test #$i : program built with system's GCC with -z execstack,-fno-stack-protector flags"
askfornext

let i=i+1
#PUT=./bof_vuln_lessprot_dbg
#test_bof ${PUT} "Test #$i : program built with system's GCC with -g -O0 -z execstack,-fno-stack-protector flags"

ASLR_reset
exit 0
