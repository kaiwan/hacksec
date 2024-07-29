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
ALL :=  send_core send_core_dbg send_core_dbg_asan send_core_dbg_ub send_core_dbg_msan \
	recv_core recv_core_dbg recv_core_dbg_asan recv_core_dbg_ub recv_core_dbg_msan \

CC=${CROSS_COMPILE}gcc
#CL=${CROSS_COMPILE}clang

PROD_OPTLEVEL=2
SECURITY_CFLAGS=-fstack-protector-strong -Wformat-security \
	-O${PROD_OPTLEVEL} -D_FORTIFY_SOURCE=${PROD_OPTLEVEL} \
	-fPIE \
	-fsanitize=bounds -fsanitize-undefined-trap-on-error -fstrict-flex-arrays

CFLAGS=-Wall ${SECURITY_CFLAGS}
CFLAGS_DBG=-g -ggdb -gdwarf-4 -O0 -Wall -Wextra ${SECURITY_CFLAGS}
CFLAGS_DBG_ASAN=${CFLAGS_DBG} -fsanitize=address
CFLAGS_DBG_MSAN=${CFLAGS_DBG} -fsanitize=memory
CFLAGS_DBG_UB=${CFLAGS_DBG} -fsanitize=undefined

all: ${ALL}
CB_FILES := *.[ch]

checksec:
	make send_core recv_core
	checksec --file=send_core
	checksec --file=recv_core

common.o: ../common.c ../common.h
	${CC} ${CFLAGS} -c ../common.c -o common.o
common_dbg.o: ../common.c ../common.h
	${CC} ${CFLAGS_DBG} -c ../common.c -o common_dbg.o

#--- Sanitizers (use clang): common_dbg_*
common_dbg_asan.o: ../common.c ../common.h
	${CL} ${CFLAGS_DBG_ASAN} -c ../common.c -o common_dbg_asan.o
common_dbg_ub.o: ../common.c ../common.h
	${CL} ${CFLAGS_DBG_UB} -c ../common.c -o common_dbg_ub.o
common_dbg_msan.o: ../common.c ../common.h
	${CL} ${CFLAGS_DBG_MSAN} -c ../common.c -o common_dbg_msan.o

send_core.o: send_core.c
	${CC} ${CFLAGS} -c send_core.c -o send_core.o
send_core: common.o send_core.o
	${CC} ${CFLAGS} -o send_core send_core.o common.o

send_core_dbg.o: send_core.c
	${CC} ${CFLAGS_DBG} -c send_core.c -o send_core_dbg.o
send_core_dbg: send_core_dbg.o common_dbg.o
	${CC} ${CFLAGS_DBG} -o send_core_dbg send_core_dbg.o common_dbg.o

#--- Sanitizers (use clang): <foo>_dbg_[asan|ub|msan]
send_core_dbg_asan.o: send_core.c
	${CC} ${CFLAGS_DBG_ASAN} -c send_core.c -o send_core_dbg_asan.o
send_core_dbg_asan: send_core_dbg_asan.o common_dbg_asan.o
	${CC} ${CFLAGS_DBG_ASAN} -o send_core_dbg_asan send_core_dbg_asan.o common_dbg_asan.o

send_core_dbg_ub.o: send_core.c
	${CC} ${CFLAGS_DBG_UB} -c send_core.c -o send_core_dbg_ub.o
send_core_dbg_ub: send_core_dbg_ub.o common_dbg_ub.o
	${CC} ${CFLAGS_DBG_UB} -o send_core_dbg_ub send_core_dbg_ub.o common_dbg_ub.o

send_core_dbg_msan.o: send_core.c
	${CC} ${CFLAGS_DBG_MSAN} -c send_core.c -o send_core_dbg_msan.o
send_core_dbg_msan: send_core_dbg_msan.o common_dbg_msan.o
	${CC} ${CFLAGS_DBG_MSAN} -o send_core_dbg_msan send_core_dbg_msan.o common_dbg_msan.o

recv_core.o: recv_core.c
	${CC} ${CFLAGS} -c recv_core.c -o recv_core.o
recv_core: common.o recv_core.o
	${CC} ${CFLAGS} -o recv_core recv_core.o common.o

recv_core_dbg.o: recv_core.c
	${CC} ${CFLAGS_DBG} -c recv_core.c -o recv_core_dbg.o
recv_core_dbg: recv_core_dbg.o common_dbg.o
	${CC} ${CFLAGS_DBG} -o recv_core_dbg recv_core_dbg.o common_dbg.o

#--- Sanitizers (use clang): <foo>_dbg_[asan|ub|msan]
recv_core_dbg_asan.o: recv_core.c
	${CC} ${CFLAGS_DBG_ASAN} -c recv_core.c -o recv_core_dbg_asan.o
recv_core_dbg_asan: recv_core_dbg_asan.o common_dbg_asan.o
	${CC} ${CFLAGS_DBG_ASAN} -o recv_core_dbg_asan recv_core_dbg_asan.o common_dbg_asan.o

recv_core_dbg_ub.o: recv_core.c
	${CC} ${CFLAGS_DBG_UB} -c recv_core.c -o recv_core_dbg_ub.o
recv_core_dbg_ub: recv_core_dbg_ub.o common_dbg_ub.o
	${CC} ${CFLAGS_DBG_UB} -o recv_core_dbg_ub recv_core_dbg_ub.o common_dbg_ub.o

recv_core_dbg_msan.o: recv_core.c
	${CC} ${CFLAGS_DBG_MSAN} -c recv_core.c -o recv_core_dbg_msan.o
recv_core_dbg_msan: recv_core_dbg_msan.o common_dbg_msan.o
	${CC} ${CFLAGS_DBG_MSAN} -o recv_core_dbg_msan recv_core_dbg_msan.o common_dbg_msan.o

# indent- "beautifies" C code into the "Linux kernel style".
# (cb = C Beautifier :) )
# Note! original source file(s) is overwritten, so we back it up.
cb: ${CB_FILES}
	mkdir bkp 2> /dev/null; cp -f ${CB_FILES} bkp/
	indent -linux ${CB_FILES}

clean:
	rm -vf ${ALL} core* vgcore* *.o *~
