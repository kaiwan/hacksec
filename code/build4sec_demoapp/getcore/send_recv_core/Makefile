# Makefile
#----------------------------------------------------------------------
# Doc/Ref: pl lookup & read the 'MITIGATING HACKERS WITH HARDENING ON LINUX -
#  AN OVERVIEW FOR DEVELOPERS, FOCUS ON BOF' PDF that's here:
# https://github.com/kaiwan/hacksec
#
#  ASSUMPTIONS ::
#   The convenience files ../common.h and ../common.c are present
#
#  (c) Kaiwan NB, kaiwanTECH
#  License: MIT
#----------------------------------------------------------------------

## Pl check and keep or remove <foo>_dbg_[asan|ub|msan] targets
## as desired.
# gcc doesn't support MSAN well enough
ALL_GCC :=  send_core send_core_dbg send_core_dbg_asan send_core_dbg_ub \
	recv_core recv_core_dbg recv_core_dbg_asan recv_core_dbg_ub
ALL_CLANG :=  send_core send_core_dbg send_core_dbg_asan send_core_dbg_ub send_core_dbg_msan \
	recv_core recv_core_dbg recv_core_dbg_asan recv_core_dbg_ub recv_core_dbg_msan

# Decide which compiler to use; GCC doesn't support MSAN, clang does
CC=${CROSS_COMPILE}gcc
ifeq (, $(shell which clang))
  $(warning === WARNING! No clang (compiler) in PATH (reqd for MSAN); consider doing 'sudo apt install clang' or equivalent ===)
else
  CC := clang
  LINKIN := -static-libsan
  ALL := $(ALL_CLANG)
endif
# Forcing to gcc (for now) as this enables (linker) 'full RELRO' (relocation ro)
CC=${CROSS_COMPILE}gcc
$(info Compiler set to $(CC))
ALL := $(ALL_GCC)

STRIP=${CROSS_COMPILE}strip
OBJCOPY=${CROSS_COMPILE}objcopy

CSTD=-ansi -std=c99 -std=c11 -std=c18  # the last one wins; else if unsupported, earlier ones...
# For the meaning of the following feature test macros, see feature_test_macros(7)
POSIX_STD=201112L
STD_DEFS=-D_DEFAULT_SOURCE -D_GNU_SOURCE


PROD_OPTLEVEL=3
  # -O<N>; N can be 0-3 or s (optimize for speed & size);
  #  in the -D_FORTIFY_SOURCE=N option, you must set N to the same number

#--- Security-related compiler flags !
# Ref: GCC security related flags reference [https://gist.github.com/kaiwan/d82d8271459c90c3accc3f795dcaf228]
SECURITY_CFLAGS_REG = -fstack-protector-strong \
	-O${PROD_OPTLEVEL} -D_FORTIFY_SOURCE=${PROD_OPTLEVEL} \
	-pie -fPIE \
	-fsanitize=bounds -fsanitize-undefined-trap-on-error \
	-fcf-protection \
	-fsanitize=signed-integer-overflow -fsanitize-undefined-trap-on-error
### NOTE- the -fcf-protection* flag(s) might not work on all archs ###

SECURITY_CFLAGS = ${SECURITY_CFLAGS_REG}
ifeq (gcc, $(CC))
   SECURITY_CFLAGS = ${SECURITY_CFLAGS_REG} -fstrict-flex-arrays
endif

# Compiler warnings
WARN = -Wall -Wextra -Wstack-protector -Wformat -Werror=format-security
WARN_MORE = ${WARN} -Wpedantic #-Werror

CFLAGS = -UDEBUG ${WARN} ${CSTD} -D_POSIX_C_SOURCE=${POSIX_STD} ${STD_DEFS} ${SECURITY_CFLAGS}
CFLAGS_DBG = -DDEBUG -g -ggdb -gdwarf-4 -Og ${WARN_MORE} -fno-omit-frame-pointer ${CSTD} -D_POSIX_C_SOURCE=${POSIX_STD} ${STD_DEFS} ${SECURITY_CFLAGS}
CFLAGS_DBG_ASAN=${CFLAGS_DBG} -fsanitize=address
CFLAGS_DBG_MSAN=${CFLAGS_DBG} -fsanitize=memory
CFLAGS_DBG_UB=${CFLAGS_DBG} -fsanitize=undefined

#--- Linker flags
# -Wl,-z,now -Wl,-z,relro : enable 'full RELRO' (relocation read-only)
LDFLAGS1=-Wl,-z,now -Wl,-z,relro
# -Wl,-z,noexecstack : enable non-executable stack
LDFLAGS2=-Wl,-z,noexecstack  #, -Wl,-z,noexecheap
LDFLAGS = ${LDFLAGS1} ${LDFLAGS2}
# For Windows add:
# -Wl,dynamicbase : tell linker to use ASLR protection
# -Wl,nxcompat : tell linker to use DEP protection

# Add this option switch to LDFLAGS if you want ltrace to work on Ubuntu!
# Conflicts with full relro though..
LTRACE_ENABLE=-z lazy

all: ${ALL}
CB_FILES := *.[ch]

CHECKSEC := checksec
checksec:
	make send_core recv_core
ifeq (, $(shell which ${CHECKSEC}))
   $(warning === WARNING! ${CHECKSEC} not installed; consider doing 'sudo apt install checksec' or equivalent ===)
else
	checksec --file=send_core
	checksec --file=recv_core
endif

common.o: ../common.c ../common.h
	${CC} ${CFLAGS} -c ../common.c -o common.o
common_dbg.o: ../common.c ../common.h
	${CC} ${CFLAGS_DBG} -c ../common.c -o common_dbg.o

#--- Sanitizers (use clang): common_dbg_*
common_dbg_asan.o: ../common.c ../common.h
	${CC} ${CFLAGS_DBG_ASAN} -c ../common.c -o common_dbg_asan.o
common_dbg_ub.o: ../common.c ../common.h
	${CC} ${CFLAGS_DBG_UB} -c ../common.c -o common_dbg_ub.o
common_dbg_msan.o: ../common.c ../common.h
	${CC} ${CFLAGS_DBG_MSAN} -c ../common.c -o common_dbg_msan.o

send_core.o: send_core.c
	${CC} ${CFLAGS} -c send_core.c -o send_core.o
send_core: common.o send_core.o
	${CC} ${CFLAGS} -o send_core send_core.o common.o ${LDFLAGS}
	${STRIP} send_core

send_core_dbg.o: send_core.c
	${CC} ${CFLAGS_DBG} -c send_core.c -o send_core_dbg.o
send_core_dbg: send_core_dbg.o common_dbg.o
	${CC} ${CFLAGS_DBG} -o send_core_dbg send_core_dbg.o common_dbg.o ${LDFLAGS}

#--- Sanitizers (use clang): <foo>_dbg_[asan|ub|msan]
send_core_dbg_asan.o: send_core.c
	${CC} ${CFLAGS_DBG_ASAN} -c send_core.c -o send_core_dbg_asan.o
send_core_dbg_asan: send_core_dbg_asan.o common_dbg_asan.o
	${CC} ${CFLAGS_DBG_ASAN} -o send_core_dbg_asan send_core_dbg_asan.o common_dbg_asan.o ${LDFLAGS}

send_core_dbg_ub.o: send_core.c
	${CC} ${CFLAGS_DBG_UB} -c send_core.c -o send_core_dbg_ub.o
send_core_dbg_ub: send_core_dbg_ub.o common_dbg_ub.o
	${CC} ${CFLAGS_DBG_UB} -o send_core_dbg_ub send_core_dbg_ub.o common_dbg_ub.o ${LDFLAGS}

send_core_dbg_msan.o: send_core.c
	${CC} ${CFLAGS_DBG_MSAN} -c send_core.c -o send_core_dbg_msan.o
send_core_dbg_msan: send_core_dbg_msan.o common_dbg_msan.o
	${CC} ${CFLAGS_DBG_MSAN} -o send_core_dbg_msan send_core_dbg_msan.o common_dbg_msan.o ${LDFLAGS}

recv_core.o: recv_core.c
	${CC} ${CFLAGS} -c recv_core.c -o recv_core.o
recv_core: common.o recv_core.o
	${CC} ${CFLAGS} -o recv_core recv_core.o common.o ${LDFLAGS}
	${STRIP} recv_core

recv_core_dbg.o: recv_core.c
	${CC} ${CFLAGS_DBG} -c recv_core.c -o recv_core_dbg.o
recv_core_dbg: recv_core_dbg.o common_dbg.o
	${CC} ${CFLAGS_DBG} -o recv_core_dbg recv_core_dbg.o common_dbg.o ${LDFLAGS}

#--- Sanitizers (use clang): <foo>_dbg_[asan|ub|msan]
recv_core_dbg_asan.o: recv_core.c
	${CC} ${CFLAGS_DBG_ASAN} -c recv_core.c -o recv_core_dbg_asan.o
recv_core_dbg_asan: recv_core_dbg_asan.o common_dbg_asan.o
	${CC} ${CFLAGS_DBG_ASAN} -o recv_core_dbg_asan recv_core_dbg_asan.o common_dbg_asan.o ${LDFLAGS}

recv_core_dbg_ub.o: recv_core.c
	${CC} ${CFLAGS_DBG_UB} -c recv_core.c -o recv_core_dbg_ub.o
recv_core_dbg_ub: recv_core_dbg_ub.o common_dbg_ub.o
	${CC} ${CFLAGS_DBG_UB} -o recv_core_dbg_ub recv_core_dbg_ub.o common_dbg_ub.o ${LDFLAGS}

recv_core_dbg_msan.o: recv_core.c
	${CC} ${CFLAGS_DBG_MSAN} -c recv_core.c -o recv_core_dbg_msan.o
recv_core_dbg_msan: recv_core_dbg_msan.o common_dbg_msan.o
	${CC} ${CFLAGS_DBG_MSAN} -o recv_core_dbg_msan recv_core_dbg_msan.o common_dbg_msan.o ${LDFLAGS}

# indent- "beautifies" C code into the "Linux kernel style".
# (cb = C Beautifier :) )
# Note! original source file(s) is overwritten, so we back it up.
cb: ${CB_FILES}
	mkdir bkp 2> /dev/null; cp -f ${CB_FILES} bkp/
	indent -linux ${CB_FILES}

clean:
	rm -vf ${ALL} core* vgcore* *.o *~
