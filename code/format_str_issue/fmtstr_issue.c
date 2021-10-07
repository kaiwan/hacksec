/*
 * fmtstr_issue.c
 * Simple test of the printf/scanf format string vuln.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

int main(int argc, char **argv)
{
	if (argc < 2) {
		fprintf(stderr, "Usage: %s param\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	printf(argv[1]);
	exit (EXIT_SUCCESS);
}
