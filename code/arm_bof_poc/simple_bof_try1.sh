#!/bin/bash
PUT=arm_bof_vuln  # Program Under Test

is_stack_guarded()
{
echo -n " $1 : Is Stack Guarded? "
readelf -s ${1} |grep -q __stack_chk_guard && echo "Yes!" || echo "Nope"
}

echo "1. BOF on ${PUT}:"
is_stack_guarded ${PUT}
perl -e 'print "A"x12 . "B"x4 . "C"x4' | ./${PUT}

echo
PUT=arm_bof_vuln_stackprot
echo "2. BOF on ${PUT}:"
is_stack_guarded ${PUT}
perl -e 'print "A"x12 . "B"x4 . "C"x4' | ./${PUT}

echo
PUT=arm_bof_vuln_fortified
echo "3. BOF on ${PUT}:"
is_stack_guarded ${PUT}
perl -e 'print "A"x12 . "B"x4 . "C"x4' | ./${PUT}
