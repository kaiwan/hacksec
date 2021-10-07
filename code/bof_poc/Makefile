# Makefile
#  for build and test on an ARM device (eg.Raspberry Pi 0W / [3+] / 4 / BeagleBone/...)
#  or an x86_64 system
# Part of my 'hacksec' github repo:
# https://github.com/kaiwan/hacksec
ALL := bof_vuln_reg bof_vuln_reg_dbg bof_vuln_reg_stripped bof_vuln_fortified bof_vuln_stackprot bof_vuln_lessprot
CC=${CROSS_COMPILE}gcc
LD=${CROSS_COMPILE}ld
STRIP=${CROSS_COMPILE}strip

DBG=-g -ggdb -gdwarf-4 -O0
CFLAGS_REG=-Wall
CFLAGS_REG_DBG=${DBG} -Wall #-Wextra

#--- Fortification and stackprot options; actually works, preventing our
# simple BOF
CFLAGS_FORT=-D_FORTIFY_SOURCE=2 -O2 -Wall #-Wextra
 # Pecuiliar : with this, checksec says its Not fortified, but stack is protected
CFLAGS_STACKPROT=-fstack-protector-strong -O2 -Wall #-Wextra
 # Pecuiliar again! with this, checksec says its fortified, but stack is Not protected
 # ??
#---

CFLAGS_LESSPROT=-z execstack -fno-stack-protector -Wall
  # -z execstack: ld(1) (linker) option to enable stack execution

all: ${ALL}

bof_vuln_reg: bof_vuln.c
	${CC} ${CFLAGS_REG} bof_vuln.c -o bof_vuln_reg
bof_vuln_reg_dbg: bof_vuln.c
	${CC} ${CFLAGS_REG_DBG} bof_vuln.c -o bof_vuln_reg_dbg
bof_vuln_reg_stripped: bof_vuln.c
	${CC} ${CFLAGS_REG} bof_vuln.c -o bof_vuln_reg_stripped
	${STRIP} --strip-all bof_vuln_reg_stripped
bof_vuln_fortified: bof_vuln.c
	${CC} ${CFLAGS_FORT} bof_vuln.c -o bof_vuln_fortified
bof_vuln_stackprot: bof_vuln.c
	${CC} ${CFLAGS_STACKPROT} bof_vuln.c -o bof_vuln_stackprot
bof_vuln_lessprot: bof_vuln.c
	${CC} ${CFLAGS_LESSPROT} bof_vuln.c -o bof_vuln_lessprot

clean:
	rm -fv ${ALL} *.o
