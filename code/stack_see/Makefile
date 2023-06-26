# Makefile
ALL = stack_see_32 stack_see_dbg_32
all: ${ALL}

CFLAGS = -Wall -O3
CFLAGS_DBG = -Wall -Wextra -O0 -g -ggdb -fno-omit-frame-pointer

# Compiling for 32-bit; requires the gcc-multilib pkg on x86-64
stack_see_32: stack_see.c
	gcc ${CFLAGS} -m32 stack_see.c -o stack_see_32
stack_see_dbg_32: stack_see.c
	gcc ${CFLAGS_DBG} -m32 stack_see.c -o stack_see_dbg_32

clean:
	rm -f ${ALL}
