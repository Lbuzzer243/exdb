source: http://www.securityfocus.com/bid/7210/info

A buffer overflow has been reported in the PHP openlog() function. By passing an argument of excessive size to the function, it may be possible for an attacker to overwrite memory, resulting in a denial of service. It is also possible for an attacker to execute arbitrary code in the PHP interpreter.

This vulnerability was reported for PHP 4.3.1 and later, however it is likely that previous versions are also affected. This issue appears to affect all platforms PHP runs on. 

<?php
openlog(str_repeat("X", 1500), LOG_PID, LOG_DAEMON);
?>