#!/bin/sh
# runiof.sh
# 2^32 = 4,294,967,296
# So for a signed int, the range is half of that, i.e.
#  -2,147,483,648 to +2,147,483,648
# 'hacksec', (c) Kaiwan NB, kaiwanTECH ; license: MIT
name=$(basename $0)

echo "${name}: background (TOO)::
A *signed* integer on 64-bit ranges from (min,max) (-2,147,483,648, +2,147,483,647)
"

#---------------BUGGY CASE--------------------------------------
if [ ! -x ./iof_try ]; then
  echo "${name}: executable iof_try not built?"
  exit 1
fi

echo "---------- Buggy iof_try --------------"
echo "Ok: ./iof_try 2147483647"
./iof_try 2147483647
echo
echo "***--- Buggy case (of IoF): ./iof_try 2147483649 ---***"
./iof_try 2147483649

#---------------FIXED CASE--------------------------------------
if [ ! -x ./iof_ok ]; then
  echo "${name}: executable iof_ok not built?"
  exit 1
fi

echo
echo "---------- Correct iof_ok --------------"
echo "./iof_ok 2147483647"
./iof_ok 2147483647
echo
echo "./iof_ok 4147483649"
./iof_ok 4147483649
