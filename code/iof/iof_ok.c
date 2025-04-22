/*
 * iof_ok.c
 * Correct prg; for an IoF - integer overflow - demo.
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
	off_t fsz = 5000, len = 2000;
	unsigned int off = 0; /* *unsigned* int explicitly declared, we want only positive values! 
			       * A dangerous potential IoF BUG is avoided!
			       */
	if (argc < 2) {
		fprintf(stderr, "Usage: %s offset\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	/*
	 IoF Poc:
	 A *signed* integer on 64-bit ranges from (min,max) (-2,147,483,648, +2,147,483,647).
	 So, if you pass a positive offset within the max it works. 
	 However, just pass the number 2,147,483,649 and see! It wraps around to
	 the negative side and the validity check below passes. Whoops!

	 BUT, here in the corrected ver, we use an *unsigned* integer, thus preventing
	 the IOF bug!
	 */
	off = atoi(argv[1]);
	printf("off = %u\n", off);
	if (off+len > fsz) {
		fprintf(stderr,
			"%s: invalid offset or offset/length combination, aborting...\n", argv[0]);
		exit(1);
	}
	printf("Ok, proceed !\n");
	// do_foo(off);
	exit(EXIT_SUCCESS);
}
