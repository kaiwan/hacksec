#!/bin/bash
# simple_bof_try1.sh
name=$(basename "$0")
CHKSEC=../../tools_sec/checksec.sh/checksec
SKIP_CHKSEC=0

checkit()
{
[ $# -ne 1 ] && return

# the readelf check below isn't reliable??
#echo -n "
#$1 : Is Stack Guarded? "
#readelf -s ${1} |grep -q __stack_chk_guard && echo "Yes!" || echo "Nope"

[ ${SKIP_CHKSEC} -eq 0 ] && {
  echo "checksec.sh:"
  ${CHKSEC} --file="${1}"
}
}

#------------ t e s t _ a r m _ b o f ----------------------------------
# Parameters:
#  $1 : pathname of PUT
#  $2 : message to print
test_arm_bof()
{
[ $# -ne 2 ] && return
local PUT=${1}         # Program Under Test
[ ! -f ${PUT} ] && {
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
[ "${re}" != "y" -a "${re}" != "Y" ] && return

perl -e 'print "A"x12 . "B"x4 . "C"x4' | ./${PUT}
}


## 'main'
if [ ! -f ${CHKSEC} ] ; then
echo "${name}: Warning! shell script \"${CHKSEC}\" missing..(will skip)"
  SKIP_CHKSEC=1
else
  echo "checksec: FYI, the meaning of the columns:
 'Fortified'   = # of functions that are actually fortified
 'Fortifiable' = # of functions that can be fortified"
fi


PUT=./arm_bof_vuln_reg
test_arm_bof ${PUT} "Test #1 : ${PUT} : built with ARM system's default gcc flags"

PUT=./arm_bof_vuln_reg_stripped
test_arm_bof ${PUT} "Test #2 : ${PUT} : built with ARM system's default gcc flags and stripped"

PUT=./arm_bof_vuln_fortified
test_arm_bof ${PUT} "Test #3 : ${PUT} : built with ARM system's gcc with fortification ON"

PUT=./arm_bof_vuln_stackprot
test_arm_bof ${PUT} "Test #4 : ${PUT} : built with ARM system's gcc with stack prot ON"

PUT=./arm_bof_vuln_lessprot
test_arm_bof ${PUT} "Test #5 : ${PUT} : built with ARM system's gcc with -z execstack,-fno-stack-protector flags"

exit 0
