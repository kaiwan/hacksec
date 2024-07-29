/*
 * 1_buggy_using-gdb-userspace.c
 * 
 * Intended as an exercise for participants.
 *
 * This program has bugs.
 * a) Find and resolve them using the GNU debugger gdb.
 * b) Then create a patch.
 *
 * The purpose of this simple program is:
 *  Given a pathname as a parameter, it queries and prints some
 *  information about it (retrieved from it's inode using the 
 *  stat(2) syscall).
 * 
 * (c) Kaiwan NB, kaiwanTECH
 */

#include <stdio.h>
#include <time.h>
#include <sys/stat.h>

main(int argc, char **argv)
{
	struct stat statbuf;
	char cmd[128];

	if (argc != 2) {
		fprintf (stderr, "Usage: %s filename\n");
		exit (1);
	}

	/* Retrieve the information using stat(2) */
	stat(argv[1], &statbuf);
		/* Notice we have not checked the failure case for stat(2)!
		 * It can be a bad bug; just try passing an invalid file as
		 * parameter to this program and see what happens :)
		 */
	/* 
	 * Lets print the foll reg the file object:
	 *  inode #, size in bytes, modification time
	 *  uid, gid
	 *  optimal block size, # of blocks
	 */
	printf("%s:\n"
		" inode number: %d : size (bytes): %d : mtime: %s\n"
		" uid: %d gid: %d\n"
		" blksize: %d blk count: %d\n",
		argv[1], statbuf.st_ino, 
		statbuf.st_size, ctime(statbuf.st_mtime),
		statbuf.st_uid, statbuf.st_gid, 
		statbuf.st_blksize, statbuf.st_blocks);
	
	exit(0);
}
