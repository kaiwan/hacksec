/*
 * arm_bof.c
 * PoC (on an ARM-32)
 * Ref: YouTube tut:
 *  https://www.youtube.com/watch?v=7P9lnpAZy60
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

static void secret_func(void)
{  
	char b[25];
	snprintf(b, 25, " CTF Secret 0x%x\n", (unsigned int)&secret_func);
	printf("YAY! Entered secret_func() !\n%s", b);
}

static void foo(char *param1)
{
	char local[12];
	gets(local);
}

int main (int argc, char **argv)
{
	foo(argv[1]);
	printf("Ok, about to exit...\n");
	exit (EXIT_SUCCESS);
}

/* vi: ts=8 */
