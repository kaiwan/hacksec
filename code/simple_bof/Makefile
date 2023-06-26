# Makefile
# Part of my 'hacksec' github repo:
# https://github.com/kaiwan/hacksec
ALL := getdata getdata_dbg getdata_fortified getdata_stackprot getdata_strongprot getdata_lessprot getdata_lessprot_dbg
CC=${CROSS_COMPILE}gcc
LD=${CROSS_COMPILE}ld
STRIP=${CROSS_COMPILE}strip

DBG=-g -O0
CFLAGS_REG=-Wall
CFLAGS_REG_DBG=${DBG} -Wall #-Wextra

#---
# DEFAULT compiler switches passed in by GCC when compiling an ordinary C program WITH debug: -g
# (Via the show_gcc_switches util in my 'usefulsnips' GitHub repo:
# Limitation: works only for ELF objects compiled with debug info, -g)
# -On x86_64, gcc ver 11.3.0:
#  C17 -mtune=generic -march=x86-64 -g -fasynchronous-unwind-tables -fstack-protector-strong -fstack-clash-protection -fcf-protection
# -On AArch64, gcc ver 10.2.1:
#  C17 -mlittle-endian -mabi=lp64 -g -fasynchronous-unwind-tables
# -On AArch32, gcc ver 20.2.1:
#  C17 -mfloat-abi=hard -mfpu=vfp -mtls-dialect=gnu -marm -march=armv6+fp -g
#---
#--- Fortification and stackprot options; actually works, preventing our simple BOF
CFLAGS_FORT=-D_FORTIFY_SOURCE=3 -Wall #-Wextra
 # Pecuiliar : with this (above line), checksec says its Not fortified, but stack is protected
 # ANS: See https://stackoverflow.com/questions/68847068/why-does-d-fortify-source-2-has-no-effect-in-my-compilation
CFLAGS_STACKPROT=-fstack-protector-strong -O0 -Wall #-Wextra
 # Pecuiliar again! with this (above line), checksec says its 'No canary found' (for stack protection)
 # NOTE : I find that using any optimization (-On or even just -O) results in the stack canary
 # being removed (at least according to checksec)!

 # Strong protections for production !
 CFLAGS_STRONG_PROT=-Wall -fstack-protector-strong -D_FORTIFY_SOURCE=3 -Werror=format-security \
  -fsanitize=bounds -fsanitize-undefined-trap-on-error #-fstrict-flex-arrays
 # NOTE : I find that using any optimization (-On or even just -O) results in the stack canary
 # being removed (at least according to checksec)!
#---

CFLAGS_LESSPROT=-z execstack -fno-stack-protector -no-pie -Wall
  # -z execstack: ld(1) (linker) option to enable stack execution

all: ${ALL}

getdata: getdata.c
	${CC} ${CFLAGS_REG} getdata.c -o getdata
getdata_dbg: getdata.c
	${CC} ${CFLAGS_REG_DBG} getdata.c -o getdata_dbg
getdata_fortified: getdata.c
	${CC} ${CFLAGS_FORT} -O0 getdata.c -o getdata_fortified
getdata_stackprot: getdata.c
	${CC} ${CFLAGS_STACKPROT} getdata.c -o getdata_stackprot
getdata_strongprot: getdata.c
	${CC} ${CFLAGS_STRONG_PROT} getdata.c -o getdata_strongprot
	${STRIP} --strip-all getdata_strongprot
getdata_lessprot: getdata.c
	${CC} ${CFLAGS_LESSPROT} getdata.c -o getdata_lessprot
getdata_lessprot_dbg: getdata.c
	${CC} ${DBG} ${CFLAGS_LESSPROT} getdata.c -o getdata_lessprot_dbg

clean:
	rm -fv ${ALL} *.o
