<#
.Synopsis
   Generic user termination  
.DESCRIPTION
   There are a few areas that need to be updated. if you're going to impliement this in your environemnt. 
.EXAMPLE
    Just run it. Don't get fancy.  
.NOTES
   This needs to be ran as an Admin. You may have to edit the output path for the Download folder. If there's already a folder with the name, the script will execute within a minute. 
#>


function Get-NewPassword{ 
    -join ((33..126) | Get-Random -Count 16 | % {[char]$_})
}

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

function Terminate-ADUser{

#This process is a 2parter. First terminate the AD account, then terminate the O365 mailbox. 
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [String] $username,
        [Parameter(Mandatory=$True)]
        [String] $TicketNumber,
        [Parameter(Mandatory=$True)]
        [String] $Techname,
        [String] $OOOMessage,
        [String] $MailForwardTo  
    )

    $UserCredential = Get-Credential 
    Connect-MsolService -credential $usercredential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session 


    $userExist = $(try {Get-ADUser $username} catch {$null})
    if ($userExist -ne $null) {
        $UserDisplayName = get-aduser -identity $username | Select name
        $userdn = $UserDisplayName.name
      write-host "The User - $userdn - Was found. Please check to make sure this is the right user" -foregroundcolor Green
      pause
    } else {
        Write-Output "Sorry, that user wasn't found. Please try again. " -foregroundcolor Red
      break
    }

    # ---------- SCRIPT STARTS HERE-------------- 
    #Enter AD username & obtain user's DN from AD
    $UserDisplayName = get-aduser -identity $username | Select name
    $ADUserAccount = $username 

    #Get the users UPN For use later when removing access to O365 
    $UserPN = get-aduser -identity $username | select Userprincipalname 

    #Get the users' Distinguished name for use later when removing O365 access
    $ADUserDN = Get-ADuser -Identity $ADUserAccount | select -ExpandProperty DistinguishedName

    #setup the log file to record down the termination events and details
    try {
        $success = "The Directory - C:\Scripts\Terminated Users - exists, we may proceed."
        $Logfile = "C:\Scripts\Terminated Users\Term-$username.log"
        Write-Host $success -foregroundcolor Green
        Logwrite($success)
    } Catch {
        $errormessage = "There was a problem writing the log file.. Please make sure that C:\Scripts\Terminated Users\ exists"  
        LogWrite($errormessage)
    } 
    $NewDesc = "Terminated per SR# $Ticketnumber, per $Techname" 
    write-host "The log file can be found here: $logfile" -foregroundcolor Green
    Write-host "and will be opened at the end of the script. " -foregroundcolor Green

    #Section 1 - Verify that the user exists
    #Section 2 - Scramble the users' passwords
    #use the function defined above to get a new string of 16 char
    $newPassword = get-newpassword
    $success="updated the password successfully ."
    $errormessage="The password was updated the password successfully ."
    try {
        $MySecureString = ConvertTo-SecureString -String $newpassword -AsPlainText -Force -ErrorAction stop -ErrorVariable $errormessage
        Set-ADAccountPassword -Identity $username -NewPassword $MySecureString -Reset -ErrorAction Stop
        Write-Host $success -foregroundcolor Green
        Logwrite($success)
    } Catch {
        LogWrite($errormessage)
    }

    #Section 3 - Disable the account 
    #$foo = Get-ADUser -identity $username | Select-Object -Property enabled
    $success="Disabled the AD account - successfully."

    try {
        Disable-ADAccount -Identity $username -ErrorAction stop
        $foo = Get-ADUser -identity $username | Select-Object -Property enabled
            #add checking that the username is good up at the top of the script
        While ($foo.enabled -ne $false){ 
            Disable-ADAccount -Identity $username -ErrorAction stop 
        }
        Write-host $success -foregroundcolor Green
        logwrite($success)
    } Catch {
            Write-host "Failed to Disable the $username" -Foregroundcolor Red
            logwrite("Failed to Disable the $username")
    }

    #Section 4 - Remove the user account from all Groups 
    Logwrite("Listing the users`' AD Groups `n-------------------------")
    try {
        $foo = Get-ADPrincipalGroupMembership $username | select name
        foreach ($i in $foo.name)
        {
            #write the group name to the log file
            Logwrite($i)
            Write-host "Removed from the group: $i"
            #Go through the groups list and remove them from the groups noted above
            if ($i -ne "Domain Users"){
                Remove-ADGroupMember -Identity "$i" -Members $username -confirm:$false -erroraction stop 
            }
        }
        logwrite ("-------------------------") 
    } Catch { 
        pause
    }

    #Section 5 - Hide the account from the GAL
    #Doing this in AD before we connect to O365. 
    ## Done
    $success = "Removed the user from the GAL - successfully."
    $errormessage = "The account wasn't hidden from the gal, please check the error logs for why"
    try{
        Set-ADUser -Identity $ADUseraccount -Replace @{msexchhidefromaddresslists=$true} -ErrorAction stop 
        write-host $success -foregroundcolor Green
        logwrite($success) 
    } catch {
        logwrite($errormessage) 
    }

    #Section 6 - Set the new description on the terminated account
    ## Done 
    $errormessage = "Was not able to update the description successfully. Please do this manually."
    $success = "Updating the Description - Successfully."
    try{
        Set-ADUser $username -Description $NewDesc -ErrorAction Stop -ErrorVariable $errormessage
        Write-host $success -foregroundcolor Green
        logwrite($success)
    } catch {
        logwrite($errormessage)
        write-host $errormessage -foregroundcolor Red 

    }
    $Phase2 = "Update Active Directory... Completed"
    logwrite($Phase2)
    $Phase2 = "~nUpdating the O365 account..."
    logwrite($Phase2)
    $success = "Disabled ActiveSync access."
    $errormessage = "ActiveSync access was not disabled. Please check manually"
    try {
        Set-CASMailbox $username -ActiveSyncEnabled $False
        Write-Host $success -foregroundcolor Green
        Logwrite($success)
    } Catch {
        LogWrite($errormessage)
    }
    $success = "Disable OWA access"
    $errormessage = "OWA access was not disabled. Please check manually"
    try {
        Set-CASMailbox $username -OWAEnabled $False
        Write-Host $success -foregroundcolor Green
        Logwrite($success)
    } Catch {
        LogWrite($errormessage)
    }

    $success = "Convert the mailbox to a shared mailbox"
    $errormessage = "The mailbox was not converted to a shared mailbox. Please check manually"
    try {
        Set-Mailbox $username –Type shared
        Write-Host $success -foregroundcolor Green
        Logwrite($success)
    } Catch {
        LogWrite($errormessage)
    }

    $success = "Confirmed that the mailbox is a shared mailbox"
    $errormessage = "Was not able to Confirm that the mailbox is a shared mailbox"
    try {
        $sharedmailboxusers = Get-Mailbox -ResultSize unlimited -RecipientTypeDetails SharedMailbox 
        foreach($i in $sharedmailboxusers){
            if($i.name -eq $userdn){
                Write-Host $success -foregroundcolor Green
                Logwrite($success)
            }else{write-host  $i}
        }
    } Catch {
        LogWrite($errormessage)
    }

    $success = "Sucessfully Removed the O365 Licenses"
    $errormessage = "Was not able to remove the O365 licenses from account. Please review manually."
    try {
        (get-MsolUser -UserPrincipalName $UserPN.userprincipalname).licenses.AccountSkuId |
        foreach{
            $text = "Removing License: $_"
            Logwrite($text)
            Set-MsolUserLicense -UserPrincipalName $UserPN -RemoveLicenses $_
        }
        Write-Host $success -foregroundcolor Green
        Logwrite($success)
    } Catch {
        LogWrite($errormessage)
    }


    try {
        $success = "Checked the licenses and the list is empty"
        $errormessage = "Was not able to remove the licenses. Please do this manually."
        $sharedmailboxusers = Get-MsolUser -UserPrincipalName $UserPN.Userprincipalname | Select-Object Licenses
        if($sharedmailboxusers.licenses.count -gt 0){
            Write-Host $errormessage -foregroundcolor Red
            Logwrite($errormessage)
        }else { 
            Write-Host $success -foregroundcolor Green
            Logwrite($success)}
    } Catch {
        LogWrite($errormessage)
        LogWrite($sharedmailboxusers)
    }
Start-process $Logfile
}