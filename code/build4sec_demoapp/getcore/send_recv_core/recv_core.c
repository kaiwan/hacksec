/* 
* recv_core.c

* The Linux kernel provides the core-file 'pipe to program' facility
* [via the /proc/sys/kernel/core_pattern proc entry].
* Take advantage of it: when a process crashes and emits a core dump,
* arrange to pipe it to this program, which will further send te core
* content over the netowrk to a receiver process.
*
* So, the project has two parts:
* 1. the program that reads the core file data from it's stdin (as it's
* setup to be piped to it via /proc/sys/kernel/core_pattern), and then
* transmits this data to a receiver process over the network :
* [core_send]
* 2. the program that is sent this data over the network connection, which
* will receive and write it to a file.
* [recv_core] : THIS code.

* Internet domain streams socket server; concurrent server.
*/
#include "../common.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <sys/wait.h>
#include <errno.h>
#include <pwd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "convenient.h"

/*
 * Ref: https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
"The range 49152–65535 (215 + 214 to 216 − 1) contains dynamic or private
ports that cannot be registered with IANA.[322] This range is used for
private or customized services, for temporary purposes, and for automatic
allocation of ephemeral ports."
*/
#define PORT_COREDATA   64740
#define MAXBUF		getpagesize()
#define RE_MAXLEN	100+256+48+8+8+1024+4096+128

#define	QLENGTH		10
#define DBG_MUST_SLEEP  0
#define	DEBUG_SLEEP	20

static int verbose = 0;

// Prevent zombies..
static void sig_child(int signum)
{
#if 0 // not reqd on 2.6+ with SA_NOCLDWAIT flag..
	int status;
	int pid;
#endif
	QP;
	return;
#if 0 // not reqd on 2.6+ with SA_NOCLDWAIT flag..
	while ((pid = wait3(&status, WNOHANG, 0)) > 0) {
		if (verbose)
			printf("parent server in SIGCHLD handler; pid=%d\n",
			       pid);
	}
#endif
}

/* 
 * Child processes this function
 * Copy the core data from the socket into a file.
 */
static int process_client(int sd)
{
	char *core_data;
	ssize_t nr=1, nw=0;
	size_t tr=0, tw=0;
	int fd_dest;

#define DEST_COREFILE  "core_dump"
	unlink(DEST_COREFILE);
	fd_dest = open(DEST_COREFILE, O_CREAT|O_WRONLY, S_IRUSR|S_IRGRP|S_IROTH);
	if (fd_dest < 0)
		FATAL("creating dest file failed\n");
	
	core_data = (char *)malloc(MAXBUF);
	if (!core_data)
		FATAL("no memory for core_data buffer\n");

	while (nr) {
		nr = file_read(sd, core_data, MAXBUF);
		if (nr < 0) {
			free(core_data);
			FATAL("file_read failed\n");
		}
		nw = file_write(fd_dest, core_data, nr);
		if (nw < 0) {
			free(core_data);
			FATAL("file_write failed\n");
		}
		tr += nr;
		tw += nw;
	}
	MSG("read total %lu bytes from sender\n"
	    "wrote total %lu bytes to file\n", tr, tw);

	free(core_data);
	close(sd);
	close(fd_dest);

	return (0);
}

int main(int argc, char *argv[])
{
	int sd, newsd;
	socklen_t clilen;
	struct sockaddr_in svr_addr, cli_addr;
	struct sigaction act;
	unsigned short port=PORT_COREDATA;

	if (argc < 2 || argc > 3) {
		fprintf(stderr, "Usage: %s receiver-ip-addr [-v]\n", argv[0]);
		exit(1);
	}

	if ((argc == 3) && (strcmp(argv[2], "-v") == 0))
		verbose = 1;

	/* Ignore SIGPIPE, so that server does not recieve it if it attempts
	   to write to a socket whose peer has closed; the write fails with EPIPE instead..
	 */
	if (signal (SIGPIPE, SIG_IGN) == SIG_ERR)
		FATAL("signal(2) failed\n");

	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
		FATAL("socket creation error");
	if (verbose)
		printf("%s: tcp socket created\n", argv[0]);

	// Initialize server's address & bind it
	// Required to be in Network-Byte-Order
	svr_addr.sin_family = AF_INET;
	svr_addr.sin_addr.s_addr = inet_addr(argv[1]);
	svr_addr.sin_port = htons(port);
	if (bind(sd, (struct sockaddr *)&svr_addr, sizeof(svr_addr)) == -1) {
		if (errno == EADDRINUSE)
			FATAL("socket bind error: port # %d already in use, use another port!\n",
				PORT_COREDATA);
		else
			FATAL("socket bind error");
	}
	if (verbose)
		printf("%s: bind done at IP %s port %d\n",
			argv[0], argv[1], port);

	if (listen(sd, QLENGTH) == -1)
		FATAL("socket listen error");
	if (verbose)
		printf("%s: listen q set up\n", argv[0]);

	act.sa_handler = sig_child;
	sigemptyset(&act.sa_mask);
	/* On 2.6 Linux, using the SA_NOCLDWAIT flag makes it easy-
	 * zombies are prevented. See man sigaction for details...
	 */
	act.sa_flags = SA_RESTART | SA_NOCLDSTOP | SA_NOCLDWAIT;
	if (sigaction(SIGCHLD, &act, 0) == -1)
		FATAL("sigaction error");
	if (verbose)
		printf("%s: SIGCHLD handler setup (zombies are history)\n", argv[0]);

	while (1) {
		if (verbose)
			printf("%s: pid %d blocking on accept()..\n",
			       argv[0], getpid());
		fflush(stdout);

		clilen = sizeof(cli_addr);
		if ((newsd = accept(sd, (struct sockaddr *)&cli_addr, &clilen)) == -1)
			FATAL("socket accept error");
		// Receiver blocks here ...

		printf("\nServer %s: client connected now from IP %s "
			   "port # %d\n",
			   argv[0], inet_ntoa(cli_addr.sin_addr), ntohs(cli_addr.sin_port));
		fflush(stdout);

		// Client connected; process..
		switch (fork()) {
		case -1:
			perror("fork error");
			fflush(stdout);
			break;

		case 0:	// Child server
#if( DBG_MUST_SLEEP == 1)
			MSG("debug %s: pid is %d\n", argv[0], getpid());
			/* for debugging with gdb/ddd etc, keep it asleep
			 * until user can have the debugger can attach to it..
			 */
			MSG("sleeping now for %ds...\n", DEBUG_SLEEP);
			sleep(DEBUG_SLEEP);
#endif
			close(sd);
			if (verbose) {
				printf("%s: child server created; pid %d\n",
				       argv[0], getpid());
				fflush(stdout);
			}

			process_client(newsd);

			if (verbose) {
				printf("%s: child server %d exiting..\n",
				       argv[0], getpid());
				fflush(stdout);
			}
			exit(0);

		default:	// Parent server
			close(newsd);
		}
	}
}
