# Makefile
#  for build and test on an ARM device (eg. Yocto Qemu / Raspberry Pi 0W / [3+] / 4 / BeagleBone/...)
#  or an x86_64 system
# Part of my 'hacksec' github repo:
# https://github.com/kaiwan/hacksec
ALL := bof_vuln_reg bof_vuln_reg_dbg bof_vuln_reg_stripped bof_vuln_fortified bof_vuln_stackprot bof_vuln_strongprot bof_vuln_lessprot bof_vuln_lessprot_dbg
CC=${CROSS_COMPILE}gcc
LD=${CROSS_COMPILE}ld
STRIP=${CROSS_COMPILE}strip

DBG=-g -Og #-O0
CFLAGS_REG=-Wall -pie -fPIE
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
CFLAGS_FORT=-O3 -D_FORTIFY_SOURCE=3 -Wall #-Wextra
 # Pecuiliar : with this (above line), checksec says its Not fortified, but stack is protected
 # ANS: See https://stackoverflow.com/questions/68847068/why-does-d-fortify-source-2-has-no-effect-in-my-compilation
CFLAGS_STACKPROT=-fstack-protector-strong -O3 -Wall #-Wextra

# Strong protections for production !
CFLAGS_STRONG_PROT=-Wall -fstack-protector -fstack-protector-strong -D_FORTIFY_SOURCE=3 -Werror=format-security \
  -fsanitize=bounds -fsanitize-undefined-trap-on-error #-fstrict-flex-arrays
 # NOTE : I find that using any optimization (-On or even just -O) results in the stack canary
 # being removed (at least according to checksec)!
#---

CFLAGS_LESSPROT=-z execstack -fno-stack-protector -no-pie -Wall
  # -z execstack: ld(1) (linker) option to enable stack execution

#--- Linker flags
# -Wl,-z,now -Wl,-z,relro : enable 'full RELRO' (relocation read-only)
LDFLAGS1=-Wl,-z,now -Wl,-z,relro
# -Wl,-z,now -Wl,-z,relro : enable 'full RELRO' (relocation read-only)
LDFLAGS2=-Wl,-z,noexecstack  #, -Wl,-z,noexecheap
LDFLAGS = ${LDFLAGS1} ${LDFLAGS2}

all: ${ALL}

bof_vuln_reg: bof_vuln.c
	${CC} ${CFLAGS_REG} bof_vuln.c -o bof_vuln_reg ${LDFLAGS}
bof_vuln_reg_dbg: bof_vuln.c
	${CC} ${CFLAGS_REG_DBG} bof_vuln.c -o bof_vuln_reg_dbg ${LDFLAGS}
bof_vuln_reg_stripped: bof_vuln.c
	${CC} ${CFLAGS_REG} bof_vuln.c -o bof_vuln_reg_stripped ${LDFLAGS}
	${STRIP} --strip-all bof_vuln_reg_stripped
bof_vuln_fortified: bof_vuln.c
	${CC} ${CFLAGS_FORT} -O0 bof_vuln.c -o bof_vuln_fortified ${LDFLAGS}
bof_vuln_stackprot: bof_vuln.c
	${CC} ${CFLAGS_STACKPROT} bof_vuln.c -o bof_vuln_stackprot ${LDFLAGS}
bof_vuln_strongprot: bof_vuln.c
	${CC} ${CFLAGS_STRONG_PROT} bof_vuln.c -o bof_vuln_strongprot ${LDFLAGS}
	${STRIP} --strip-all bof_vuln_strongprot
bof_vuln_lessprot: bof_vuln.c
	${CC} ${CFLAGS_LESSPROT} bof_vuln.c -o bof_vuln_lessprot
bof_vuln_lessprot_dbg: bof_vuln.c
	${CC} ${DBG} ${CFLAGS_LESSPROT} bof_vuln.c -o bof_vuln_lessprot_dbg

clean:
	rm -fv ${ALL} *.o
