#!/bin/sh
# runiof.sh
# 2^32 = 4,294,967,296
# So for a signed int, the range is half of that, i.e.
#  -2,147,483,648 to +2,147,483,648
# 'hacksec', (c) Kaiwan NB, kaiwanTECH ; license: MIT
name=$(basename $0)

echo "${name}: background (TOO - Theory Of Operation)::
A *signed* integer on 64-bit ranges from (min,max) (-2,147,483,648, +2,147,483,647)
"

#---------------BUGGY CASE--------------------------------------
if [ ! -x ./iof_try ]; then
  echo "${name}: executable iof_try not built?"
  exit 1
fi

echo "---------- Buggy program iof_try --------------"
echo "Ok: ./iof_try 21"
./iof_try 21
echo "# passed above (21) is within acceptable range, so it's okay..."

echo
echo "***--- Buggy case (of IoF): ./iof_try 2147483649 ---***"
./iof_try 2147483649
echo "
Here, the # passed (2147483649) is OUTSIDE the acceptable range and NOT caught;
this is as it wraps around to -ve, as the code's wrong (using a signed int),
thus passing the program logic's validity check; clearly an IoF bug!"

#---------------FIXED CASE--------------------------------------
if [ ! -x ./iof_ok ]; then
  echo "${name}: executable iof_ok not built?"
  exit 1
fi

echo
echo "---------- Correct program iof_ok --------------"
echo "./iof_ok 21"
./iof_ok 21
echo "# passed above (21) is within acceptable range, so it's okay..."
echo
echo "./iof_ok 4147483649"
./iof_ok 4147483649
echo "
Here, the # passed (2147483649) is OUTSIDE the acceptable range, but as the code's 
correct (using an unsigned int), the potential IoF bug's caught!"
