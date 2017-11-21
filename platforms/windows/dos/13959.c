#######################################################################

                             Luigi Auriemma

Application:  TeamSpeak 3
              http://www.teamspeak.com
Versions:     <= 3.0.0-beta23
              2.x not affected
Platforms:    Windows, Mac OS X and Linux
Bugs:         A] execution of various admin commands
              B] various failed assertions
              C] various NULL pointer dereferences
Exploitation: remote, versus server
Date:         16 Jun 2010
Author:       Luigi Auriemma
              e-mail: aluigi@autistici.org
              web:    aluigi.org


#######################################################################


1) Introduction
2) Bugs
3) The Code
4) Fix


#######################################################################

===============
1) Introduction
===============


TeamSpeak 3 is the latest and current version of one of the most
popular VOIP softwares intended mainly for gamers where exists just a
florid market of hosters for renting servers.


#######################################################################

=======
2) Bugs
=======


First a small introduction and a little explanation about why the old
2.x versions aren't vulnerable.
From the major version 3.x TeamSpeak has completely changed the whole
protocol used by the Standard Port (UDP 9987) adding encryption with
variable ivec (uses libtomcrypt) and using 7 channels for each type of
packet, like channel 2 for the commands packets.

All the vulnerabilities below are exploitable by unauthenticated users
and even via one single UDP packet making it possible to spoof it and
bypassing any possible IP based filter on the server.


--------------------------------------
A] execution of various admin commands
--------------------------------------

The commands available through channel 2 are exactly those available
in the TeamSpeak 3 ServerQuery Manual (doc\ts3_serverquery_manual.pdf)
and partially those available through the TCP port 10011.

They can be used to change practically any aspect of the server and
the hosted virtual servers but obviously they require some permissions.
The problem is that through this particular way (the standard port's
channel) and before any login/join on the server (so just the first
packet) it's possible to execute even some of those commands that
require permissions.

The following is a list of commands that have been tested with success:
  banclient
  bandel
  channeladdperm/channeldelperm
  channelclientaddperm/channelclientdelperm
  channeldelete
  channeledit
  some others channelgroup* commands
  channelmove
  clientaddperm/clientdelperm
  clientdbdelete
  clientget* commands
  clientkick
  clientmove
  clientpoke
  messageadd
  sendtextmessage
  serveredit
  servergroupadd
  other servergroup* commands
  setclientchannelgroup
  tokenadd/tokendel
  various "view-only" commands but they don't print the output back
  ... other commands

Who knows a bit how the configuration of TeamSpeak works or has given a
quick look to the manual can understand the dangerousness caused by the
execution of some of these commands.
The following are some examples and scenarios:

- serveredit
  through this command is possible to configure the server/virtual
  server modifying any possible option like adding a custom join
  password, setting the number of max clients to zero so that nobody
  can join, changing the admin group, setting a custom filebase (the
  disk location where are saved all the avatars of the clients and
  other files), setting custom banners and host message, disable logs,
  disable uploads and downloads, change the server's port, retrieving
  all the IPs and "suid" of any client in the server through the
  setting of virtualserver_hostbanner_gfx_url and other things

- sendtextmessage
  it's possible to use this command for sending a message to the main
  channel or to specific channels and clients from the user "Server",
  good for social engineering and flooding (clients will freeze in
  some cases)

- channel*
  it's possible to delete and move the channels created by the users

- client* and ban*
  it's possible to kick and ban any client currently in the server
  and even unban any permanent and temporary ban or deleting the users
  from the database and so on

- clientpoke
  this particular command spawns a dialog box on the client containing
  a message (annoyance)

- messageadd
  sends offline messages from the server (possible social engineering)

- token* and servergroup*
  these commands could be used for gaining more privileges anyway I
  have not understood and tested them much

Note that, upon success, the output of the commands is not returned
making the "view-only" commands available through this method (like
version, permissionlist, clientgetids and the others) enough useless
while a message is returned in case of errors and unavailable or
incomplete commands.
This could be enough ugly in some cases where are needed IDs and other
numeric identificators for channels and clients but most of them can
be retrieved probably from the protocol of a normal client and from
the info available from there otherwise it's possible to brute force
them.

Note also that exist some commands not listed yet in the official
ServerQuery manual because are commands used by the client for itself
like clientsitereport, setwhisperlist and so on.

Although "serveredit" is already a critical command I have not tested
if it's possible to become superadmin (I mean to login in the server
through a token or the TCP interface for administering it "normally"
like a normal admin without using this vulnerability because
"serveredit" is already a superadmin command) or causing more system
damages like files reading and overwriting.
UPDATE:
the "serveraddgroupclient" command is the one for assigning superadmin
privileges to users.

It's also important to highlight the "virtualserver_hostbanner_gfx_url"
parameter of "serveredit" because the client automatically loads that
url at regular intervals or when it joins the server or each time it
gets modified and http:// is not the only protocol handler that can be
used (ftp://, file:// and any other one supported by the client's
browser) so it "could" be used for exploiting particular clientside
bugs (like freezing/crashing it with particular files) or for forcing
the clients to exploit external web server vulnerabilities and other
possible things.
But yeah this is not related to this advisory or should require a
separate bug section.


----------------------------
B] various failed assertions
----------------------------

Some of the available TeamSpeak 3 commands used via the standard's port
method cause various failed assertions on the server that will
terminate silently.
The following is the list of the commands and relative assertions:

  banlist                     Assertion "invokerClientID != 0" failed at server\serverlib\virtualserver.cpp:7442; 
  complainlist                Assertion "client != 0" failed at server\serverlib\permission_manager.cpp:167; 
  servernotifyunregister      not implemented
  serverrequestconnectioninfo Assertion "client != 0" failed at server\serverlib\permission_manager.cpp:167; 
  setconnectioninfo           Assertion "clID != 0" failed at common\packethandler.cpp:367; 
  servernotifyregister event=server   not implemented


------------------------------------
C] various NULL pointer dereferences
------------------------------------

Exactly as above except that the following are all NULL pointers that
cause a crash of the server:

  bandelall
  channelcreate channel_name=name
  channelsubscribe cid=1
  channelsubscribeall
  banadd ip=1.2.3.4
  clientedit clid=1 client_description=none
  messageupdateflag msgid=1 flag=1
  complainadd tcldbid=1 message=none
  complaindelall tcldbid=1
  ftinitupload clientftfid=1 name=file.txt cid=5 cpw= size=9999 overwrite=1 resume=0
  ftgetfilelist cid=1 cpw= path=\/
  ftdeletefile cid=1 cpw= name=\/
  ftcreatedir cid=1 cpw= dirname=\/
  ftrenamefile cid=1 cpw= tcid=1 tcpw=secret oldname=\/ newname=\/
  ftinitdownload clientftfid=1 name=\/ cid=1 cpw= seekpos=0


#######################################################################

===========
3) The Code
===========


http://aluigi.org/poc/teamspeakrack.zip
https://github.com/offensive-security/exploit-database-bin-sploits/raw/master/sploits/13959.zip (teamspeakrack.zip)


#######################################################################

======
4) Fix
======


No fix.

UPDATE:
version 3.0.0-beta25


#######################################################################