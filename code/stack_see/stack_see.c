/*
* stack-frame_pg20.c
*
* (c) pg 20 the *superb* book "Hacking: the Art of Exploitation" by Jon Erickson,
* No Starch Press.
*
* Slightly modified, knb.
*
IA-32 (/ ARM-32) Stack Layout
[...      <-- 'Top' (ESP); lower addresses
[...
LOCALS
...]
[EBP]     <-- EBP (or SFP) = pointer to previous stack frame [optional]
RET addr
[...
PARAMS
...]      <-- 'Bottom'; lower addresses

*/
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

void testfunc(int a, int b, int c, int d)
{
	char flag=0xff;
	char buffer[10];

	memset(buffer, 0xae, 10);
    printf("RET addr is %p\n", __builtin_return_address(0));
}

int main()
{
	testfunc(1, 2, 3, 4);
	exit(0);
}
