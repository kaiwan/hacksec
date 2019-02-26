# Makefile
ALL := arm_bof_vuln arm_bof_vuln_fortified arm_bof_vuln_stackprot
CC=${CROSS_COMPILE}gcc
LD=${CROSS_COMPILE}ld
DBG=-g -ggdb -gdwarf-4 -O0
CFLAGS=${DBG} -Wall -Wextra
CFLAGS_FORT=-D_FORTIFY_SOURCE=2 -O2 -Wall -Wextra
CFLAGS_STKPROT=-fstack-protector-strong -O2 -Wall -Wextra

all: ${ALL}

arm_bof_vuln: arm_bof_vuln.c
	${CC} ${CFLAGS} arm_bof_vuln.c -o arm_bof_vuln
	#${CC} ${CFLAGS} -o $@ $<
arm_bof_vuln_fortified: arm_bof_vuln.c
	${CC} ${CFLAGS_FORT} arm_bof_vuln.c -o arm_bof_vuln_fortified
arm_bof_vuln_stackprot: arm_bof_vuln.c
	${CC} -g ${CFLAGS_STKPROT} arm_bof_vuln.c -o arm_bof_vuln_stackprot
clean:
	rm -fv ${ALL} *.o
