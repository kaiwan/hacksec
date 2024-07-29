/*
 * core_send.c
 * 
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
 * [core_send] : THIS code.
 * 2. the program that is sent this data over the network connection, which
 * will receive and write it to a file.
 * [recv_core]
 *
 * History:
 *
 * Author(s) : 
 * Kaiwan N Billimoria
 *  <kaiwan -at- kaiwantech -dot- com>
 *
 * License(s): MIT permissive
 */
#include "../common.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>  // inet_ntop
#include <netinet/in.h>  // get_in_addr
#include <netinet/ip.h>  // get_in_addr
#include <string.h>
#include <assert.h>
#include "convenient.h"

/*---------------- Macros -------------------------------------------*/
/*
 * Ref: https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
"The range 49152–65535 (215 + 214 to 216 − 1) contains dynamic or private
ports that cannot be registered with IANA.[322] This range is used for
private or customized services, for temporary purposes, and for automatic
allocation of ephemeral ports."
*/
#define PORT_COREDATA   64740

/*---------------- Typedef's, constants, etc ------------------------*/
#define NR_READMAX   getpagesize()

/*---------------- Functions ----------------------------------------*/

/*
 * We're connected by now to our peer receiver process.
 * Send the buffer content across!
 */
static ssize_t send_core(void *sbuf, int len, int sd)
{
	ssize_t nw=1;

	assert(sbuf);
	//MSG("sbuf=%p sd=%d\n", sbuf, sd);

	nw = file_write(sd, sbuf, len);
	if (nw < 0)
		return -1;
	MSG("wrote %lu bytes to receiver peer...\n", nw);
	return nw;
}

static void read_and_send_core(int src_fd, int sd)
{
	ssize_t nr=1, nw=1;
	size_t tr=0;
	static size_t tw=0;
	char *buf;

	buf = malloc(NR_READMAX);
	if (!buf)
		FATAL("malloc failed\n");

	// TODO : sendfile(2) ??
	
	while (nr) {
		nr = file_read(src_fd, buf, NR_READMAX);
		if (nr < 0) {
			free(buf);
			FATAL("file_read failed\n");
		}
		if (!nr)
			break;
		tr += nr;
		nw = send_core(buf, nr, sd);
		if (nw < 0) {
			free(buf);
			FATAL("file_write failed\n");
		}
		tw += nw;
	}
	MSG("\nread  : total %lu bytes from fd %d\n"
	      "wrote : total %lu bytes to socket %d\n", 
			tr, src_fd, tw, sd);
	free(buf);
}

/*
 * Sets up the connection to our perr - the receiver process.
 * Returns: the socket fd on success, -1 on failure.
 */
static int setup_client_conn(char *host, char *port)
{
	int sd, rv, i=0;
	struct addrinfo hints, *servinfo, *p;

	memset(&hints, 0, sizeof hints);
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_ALL;

        /*
	int getaddrinfo(const char *node, const char *service,
                       const struct addrinfo *hints,
                       struct addrinfo **res);
	*/
	MSG("issuing the getaddrinfo lib API now...\n");
	if ((rv = getaddrinfo(host, port, &hints, &servinfo)) != 0)
		FATAL("getaddrinfo: %s\n", gai_strerror(rv));

	/*
 	The getaddrinfo() function allocates and initializes a linked list of addrinfo 
	structures, one for each network address that  matches  node and  service, 
	subject to any restrictions imposed by hints, and returns a pointer to the start 
	of the list in res.  The items in the linked list are linked by the ai_next field.

	Loop (over the linked list) through all the results and connect to the
	first we can..
	*/
	for (p = servinfo; p != NULL; p = p->ai_next) {
		if ((sd = socket(p->ai_family, p->ai_socktype,
				     p->ai_protocol)) == -1) {
			perror("core_send: socket");
			continue;
		}
		MSG(" loop iteration #%d: got socket fd [%d]..\n",
				++i, sd);

		printf(" %s: now attempting to connect to %s:%s...\n",
			__FUNCTION__, host, port);
		if (connect(sd, p->ai_addr, p->ai_addrlen) == -1) {
			close(sd);
			//perror("core_send: connect failed");
			continue;
		}
		break;
	}

	if (p == NULL) {
		fprintf(stderr, "client_any: failed to connect\n");
		return -1;
	}

	freeaddrinfo(servinfo);	// all done with this structure
	return sd;
}

int main(int argc, char **argv)
{
	int sd;
	char *port_str;

	if (argc != 2) {
		fprintf(stderr, "Usage: %s receiver-hostname-or-IPaddr\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	port_str = malloc(32);
	if (!port_str)
		FATAL("malloc failed\n");
	snprintf(port_str, 32, "%d", PORT_COREDATA);

	sd = setup_client_conn(argv[1], port_str);
	if (sd < 0) {
		free(port_str);
		FATAL("Failed to connect to our peer receiver [setup_client_conn()]\n"
			"Is the receiver processing running on the remote end?");
	}
	printf("%s: Connected to %s:%s ...\n", argv[0], argv[1], argv[2]);
	read_and_send_core(STDIN_FILENO, sd);

	free(port_str);
	exit(EXIT_SUCCESS);
}

/* vi: ts=8 */
