source: http://www.securityfocus.com/bid/7382/info

A denial of service vulnerability has been reported for Xinetd. The vulnerability exists due to memory leaks occuring when connections are rejected.

Numerous, repeated connections to a vulnerable Xinetd server will result in the consumption of all available memory resources thereby causing a denial of service condition. 

while true; do telnet localhost chargen < /dev/null; done;