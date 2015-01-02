The Exploit-Database Git Repository
===================================

This is the official repository of [The Exploit Database](http://www.exploit-db.com), a project sponsored by [Offensive Security](https://www.offensive-security.com).

The Exploit Database is an archive of public exploits and corresponding vulnerable software, developed for use by penetration testers and vulnerability researchers. Its aim is to serve as the most comprehensive collection of exploits gathered through direct submissions, mailing lists, and other public sources, and present them in a freely-available and easy-to-navigate database. The Exploit Database is a repository for exploits and proof-of-concepts rather than advisories, making it a valuable resource for those who need actionable data right away.

This repository is updated daily with the most recently added submissions.

Included with this repository is the **searchsploit** utility, which will allow you to search through the exploits using one or more terms.

```
root@kali:~# searchsploit -h
Usage  : searchsploit [OPTIONS] term1 [term2] ... [termN]
Example: searchsploit oracle windows local

=========
 OPTIONS
=========
 -c         - Perform case-sensitive searches; by default,
              searches will try to be greedy
 -v         - By setting verbose output, description lines
              are allowed to overflow their columns
 -h, --help - Show help screen

NOTES:
 - Use any number of search terms you would like (minimum: 1)
 - Search terms are not case sensitive, and order is irrelevant

root@kali:~# searchsploit afd windows local
----------------------------------------------------------------|----------------------------------
Description                                                     |  Path
----------------------------------------------------------------|----------------------------------
MS Windows XP/2003 AFD.sys Privilege Escalation Exploit (K-plug | /windows/local/6757.txt
Microsoft Windows xp AFD.sys Local Kernel DoS Exploit           | /windows/dos/17133.c
Windows XP/2003 Afd.sys - Local Privilege Escalation Exploit (M | /windows/local/18176.py
Windows - AfdJoinLeaf Privilege Escalation (MS11-080)           | /windows/local/21844.rb
----------------------------------------------------------------|----------------------------------
root@kali:~#
```
 
