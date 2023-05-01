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
-----------------------------------------------------------------------"
checkit ${PUT}

local re
echo -n "Run BOF on ${PUT}? [y/N] "
read re
[[ "${re}" != "y" -a "${re}" != "Y" ]] && return

perl -e 'print "A"x12 . "B"x4 . "C"x4' | ./${PUT}

# Our program ${PUT} will terminate with an exit status:
# Exit codes ref: https://www.geeksforgeeks.org/exit-codes-in-c-c-with-examples/
local stat=$?
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
PUT=./bof_vuln_reg
test_bof ${PUT} "Test #1 : ${PUT} : built with system's default gcc flags"

PUT=./bof_vuln_reg_stripped
test_bof ${PUT} "Test #2 : ${PUT} : built with system's default gcc flags and stripped"

PUT=./bof_vuln_fortified
test_bof ${PUT} "Test #3 : ${PUT} : built with system's gcc with fortification ON"

PUT=./bof_vuln_stackprot
test_bof ${PUT} "Test #4 : ${PUT} : built with system's gcc with stack prot ON"

PUT=./bof_vuln_lessprot
test_bof ${PUT} "Test #5 : ${PUT} : built with system's gcc with -z execstack,-fno-stack-protector flags"

PUT=./bof_vuln_lessprot_dbg
test_bof ${PUT} "Test #5 : ${PUT} : built with system's gcc with -g -O0 -z execstack,-fno-stack-protector flags"

exit 0
