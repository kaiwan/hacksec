# Makefile
ALL := iof_try iof_ok
all: ${ALL}
CC := ${CROSS_COMPILE}gcc
CFLAGS := -O2 -Wall
CFLAGS_DBG := -DDEBUG -O0 -g -ggdb -Wall -Wextra

iof_try: iof_try.c
	${CC} ${CFLAGS_DBG} iof_try.c -o iof_try

iof_ok: iof_ok.c
	${CC} ${CFLAGS_DBG} iof_ok.c -o iof_ok
clean:
	rm -f *.o ${ALL} 2>/dev/null
