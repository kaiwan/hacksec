/*
 * iof_try.c
 * Buggy demo for the IoF (integer overflow) bug..
 *
 * Author(s) : 
 * Kaiwan N Billimoria
 *  <kaiwan -at- kaiwantech -dot- com>
 * License(s): MIT permissive
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

int main(int argc, char **argv)
{
	off_t fsz = 2147483647; //5000, 
	off_t len = 5;
	int off = 0; /* this is a *signed* int, BUT it's a var where we want
	              * only positive values! A BUG waiting to strike!
		      */

	if (argc < 2) {
		fprintf(stderr, "Usage: %s offset\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	/*
	 IoF PoC:
	 A signed integer on 64-bit ranges from (min,max) (-2,147,483,648, +2,147,483,647).
	 So, if you pass a positive offset within the max value, it works. 
	 However, just pass the number 2,147,483,649 and see what happens! It wraps around to
	 the negative side and the validity check below passes. Whoops!
	 */
	off = atoi(argv[1]);
	printf("off = %d, len=%ld; fsz=%ld\n", off, len, fsz);
	printf("(Here, we want off+len to be within the fsz value %ld\n"
	" So, now, off+len = %ld)\n", fsz, (off+len));
	if (off+len > fsz) {
		fprintf(stderr,
			"%s: invalid offset or offset/length combination, aborting...\n"
			"(here, we want off+len to be within the value %ld)\n", argv[0], fsz);
		exit(1);
	}
	printf("Ok, proceed !\n");
	// do_foo(off);
	exit(EXIT_SUCCESS);
}
