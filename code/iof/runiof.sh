#!/bin/sh
# runiof.sh
# 2^32 = 4,294,967,296
# So for a signed int, the range is half of that, i.e.
#  -2,147,483,648 to +2,147,483,648

echo "---------- Buggy iof_try --------------"
echo "Ok: ./iof_try 2147483647"
./iof_try 2147483647
echo
echo "***--- Buggy case (of IoF): ./iof_try 2147483649 ---***"
./iof_try 2147483649

echo
echo "---------- Correct iof_ok --------------"
echo "./iof_ok 2147483647"
./iof_ok 2147483647
echo "./iof_ok 4147483649"
./iof_ok 4147483649
