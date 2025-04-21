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

source ./colors.sh

# wrapper over checksec script
checksecit()
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
#  $3 : the CFLAGS and LDFLAGS values that the program was built with
# [$4]: optional msg
test_bof()
{
[[ $# -lt 3 ]] && {
  echo "$0: pass params as reqd"; return
}
local PUT=${1}         # Program Under Test
[[ ! -f ${PUT} ]] && {
  echo "${name}: binary executable \"${PUT}\" missing..(run 'make')"
  return
}

echo "
-----------------------------------------------------------------------"
bold ${2}
echo -n "CFLAGS, LDFLAGS : "
blue_fg "${3}"
[[ $# -eq 4 ]] && gray_fg "$4"
ls -lh ${PUT}
echo "-----------------------------------------------------------------------"
checksecit ${PUT}

local re
echo -n "Run BOF on ${PUT}? [Y/n] "
read re
[[ "${re}" = "n" || "${re}" = "N" ]] && return

set +e # turn off 'strict fail'
### Run the PUT overflowing the stack buffer (it's 12 bytes, send 20) ###
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
	echo "Resetting ASLR to ON (${ASLR_VAL}) now"
	sudo sh -c "echo ${ASLR_VAL} > /proc/sys/kernel/randomize_va_space"
 }
}

trap 'ASLR_reset ; exit 1' INT QUIT

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
export ASLR_VAL=$(cat /proc/sys/kernel/randomize_va_space)
[[ ${ASLR_VAL} -ne 0 ]] && {
	echo "
	*** WARNING ***
ASLR is ON; prg may not work as expected!
Will attempt to turn it OFF now ...
"
sudo sh -c "echo 0 > /proc/sys/kernel/randomize_va_space"
aslr=$(cat /proc/sys/kernel/randomize_va_space)
[[ ${aslr} -ne 0 ]] && echo "*** WARNING *** ASLR still ON" || echo "Ok, ASLR is now Off"
}

##--- all CFLAGS_* vars - copied in from the Makefile
## Keep in sync!
CFLAGS_REG="-Wall -pie -fPIE"
CFLAGS_REG_DBG="-Og -Wall"
CFLAGS_FORT="-O3 -D_FORTIFY_SOURCE=3 -Wall"
 # Pecuiliar : with this (above line), checksec says its Not fortified, but stack is protected
 # ANS: See https://stackoverflow.com/questions/68847068/why-does-d-fortify-source-2-has-no-effect-in-my-compilation
CFLAGS_STACKPROT="-fstack-protector-strong -O3 -Wall"
# Strong protections for production !
CFLAGS_STRONG_PROT="-Wall -fstack-protector -fstack-protector-strong -D_FORTIFY_SOURCE=3 -Werror=format-security \
  -fsanitize=bounds -fsanitize-undefined-trap-on-error" #-fstrict-flex-arrays
 # NOTE : I find that using any optimization (-On or even just -O) results in the stack canary
 # being removed (at least according to checksec)!
CFLAGS_LESSPROT="-z execstack -fno-stack-protector -no-pie -Wall"
  # -z execstack: ld(1) (linker) option to enable stack execution
#--- Linker flags
# -Wl,-z,now -Wl,-z,relro : enable 'full RELRO' (relocation read-only)
LDFLAGS1="-Wl,-z,now -Wl,-z,relro"
# -Wl,-z,now -Wl,-z,relro : enable 'full RELRO' (relocation read-only)
LDFLAGS2="-Wl,-z,noexecstack"
LDFLAGS="${LDFLAGS1} ${LDFLAGS2}"
##

# PUT = Program Under Test
i=1
PUT=./bof_vuln_reg
test_bof ${PUT} "Test #$i : program built with system's default GCC flags" \
 "${CFLAGS_REG} ${LDFLAGS}"
askfornext

#let i=i+1
#PUT=./bof_vuln_reg_stripped
#test_bof ${PUT} "Test #2 : program built with system's default GCC flags and stripped" ${CFLAGS_REG}
#askfornext

let i=i+1
PUT=./bof_vuln_fortified
OPT_MSG="[Pecuiliar : even with these CFLAGS, checksec says its Not fortified, but the stack *is* protected
See https://stackoverflow.com/questions/68847068/why-does-d-fortify-source-2-has-no-effect-in-my-compilation ]"
test_bof ${PUT} "Test #$i : program built with system's GCC with fortification ON" \
 "${CFLAGS_FORT} ${LDFLAGS}" \
 "${OPT_MSG}"
askfornext

let i=i+1
PUT=./bof_vuln_stackprot
test_bof ${PUT} "Test #$i : program built with system's GCC with stack prot ON" \
 "${CFLAGS_STACKPROT} ${LDFLAGS}"
askfornext

let i=i+1
PUT=./bof_vuln_strongprot
OPT_MSG="[NOTE : I find that using any optimization (-On or even just -O) results in the stack canary being removed (at least according to checksec)!]"
test_bof ${PUT} "Test #$i : program built with system's GCC with 'STRONG' (ALL) protections ON" \
 "${CFLAGS_STRONG_PROT} ${LDFLAGS}" \
 "${OPT_MSG}"
askfornext

let i=i+1
PUT=./bof_vuln_lessprot
test_bof ${PUT} "Test #$i : program built with system's GCC with LESS protections" \
 "${CFLAGS_LESSPROT}"
askfornext

let i=i+1
#PUT=./bof_vuln_lessprot_dbg
#test_bof ${PUT} "Test #$i : program built with system's GCC with -g -O0 -z execstack,-fno-stack-protector flags" "${CFLAGS_REG}"

ASLR_reset
exit 0
