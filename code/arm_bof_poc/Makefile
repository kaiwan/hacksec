# Makefile
#  for build and test on an ARM device (eg.Raspberry Pi [3+]/BeagleBone/...)
ALL := arm_bof_vuln_reg arm_bof_vuln_reg_dbg arm_bof_vuln_reg_stripped arm_bof_vuln_fortified arm_bof_vuln_stackprot arm_bof_vuln_lessprot
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
  # -z execstack: ld(1) (linker) opt to enable stack execution

all: ${ALL}

arm_bof_vuln_reg: arm_bof_vuln.c
	${CC} ${CFLAGS_REG} arm_bof_vuln.c -o arm_bof_vuln_reg
arm_bof_vuln_reg_dbg: arm_bof_vuln.c
	${CC} ${CFLAGS_REG_DBG} arm_bof_vuln.c -o arm_bof_vuln_reg_dbg
arm_bof_vuln_reg_stripped: arm_bof_vuln.c
	${CC} ${CFLAGS_REG} arm_bof_vuln.c -o arm_bof_vuln_reg_stripped
	${STRIP} --strip-all arm_bof_vuln_reg_stripped
arm_bof_vuln_fortified: arm_bof_vuln.c
	${CC} ${CFLAGS_FORT} arm_bof_vuln.c -o arm_bof_vuln_fortified
arm_bof_vuln_stackprot: arm_bof_vuln.c
	${CC} ${CFLAGS_STACKPROT} arm_bof_vuln.c -o arm_bof_vuln_stackprot
arm_bof_vuln_lessprot: arm_bof_vuln.c
	${CC} ${CFLAGS_LESSPROT} arm_bof_vuln.c -o arm_bof_vuln_lessprot

clean:
	rm -fv ${ALL} *.o
