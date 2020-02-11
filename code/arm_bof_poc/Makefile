# Makefile
ALL := arm_bof_vuln_reg arm_bof_vuln_reg_stripped arm_bof_vuln_lessprot
CC=${CROSS_COMPILE}gcc
LD=${CROSS_COMPILE}ld
STRIP=${CROSS_COMPILE}strip

DBG=-g -ggdb -gdwarf-4 -O0
CFLAGS_REG=-Wall
CFLAGS_REG_DBG=${DBG} -Wall #-Wextra
CFLAGS_LESSPROT=-z execstack -fno-stack-protector -Wall
  # -z execstack: ld(1) (linker) opt to enable stack execution

all: ${ALL}

arm_bof_vuln_reg: arm_bof_vuln.c
	${CC} ${CFLAGS_REG} arm_bof_vuln.c -o arm_bof_vuln_reg
arm_bof_vuln_reg_stripped: arm_bof_vuln.c
	${CC} ${CFLAGS_REG} arm_bof_vuln.c -o arm_bof_vuln_reg_stripped
	${STRIP} --strip-all arm_bof_vuln_reg_stripped
arm_bof_vuln_lessprot: arm_bof_vuln.c
	${CC} ${CFLAGS_LESSPROT} arm_bof_vuln.c -o arm_bof_vuln_lessprot

clean:
	rm -fv ${ALL} *.o
