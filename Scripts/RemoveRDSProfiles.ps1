#Windows PowerShellCopy Code########################################################################### 
# 
# NAME: Remove-RDSProfile.ps1 
# 
# AUTHOR: John Grenfell 
# EMAIL: john.grenfell@wiltshire.ac.uk 
# 
# COMMENT: Remove RDS profile from a number of #servers. Find the users SID, remove the registry #key and delete the cached profile. 
 
# You have a royalty-free right to use, modify, reproduce, and 
# distribute this script file in any way you find useful, provided that 
# you agree that the creator, owner above has no warranty, obligations, 
# or liability for such use. 
# 
# VERSION HISTORY: 
# 1.8 21.12.2010 - Beta release 
# 
# Don't enumerate reg - lookup SID in AD - Done 
# Ping server before you try to connect  - Done 
# 
# 
# 
########################################################################### 
 
Import-Module ActiveDirectory 
 
$Servers = @("rdsrv1","rdsrv2","rdsrv3","ardsrv1","ardsrv2","ardsrv4","brdsrv1","brdsrv2","brdsrv3","brdsrv4") 
$MainKey = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" 
$SearchForUser = "steve" 
$ADUser = Get-ADUSER $SearchForUser 
Write-Host $ADUser.Name "SID is" $ADuser.SID 
$UserSID = $ADuser.SID 
 
Function Get-Registry(){ 
Param($MachineName = ".") 
 
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $MachineName) 
    $RegKey= $Reg.OpenSubKey("$UsersProfileKey") 
     
    #Do check you opened the key by checking its name 
    If ($RegKey.Name -eq "HKEY_LOCAL_MACHINE\$UsersProfileKey"){ 
        Write-Host "$MachineName - CAUTION going to execute ::- $Reg.DeleteSubKeyTree($UsersProfileKey)" 
        $Reg.DeleteSubKeyTree("$UsersProfileKey") 
        Write-Host "$MachineName - CAUTION going to execute ::  &rmdir \\$MachineName\c$\users\$SearchForUser /S /Q" 
        Test-Path \\$MachineName\c$\users\$SearchForUser 
        $command = " /c rmdir \\$MachineName\c$\users\$SearchForUser /S /Q" 
        [Diagnostics.Process]::Start('cmd',"$command") 
     
    } 
} 
 
Function Ping-Test(){ 
Param($TestHost = ".") 
    $Ping = Test-Connection $TestHost -count 1 -quiet 
 
    If(!$Ping) 
    { 
     Write-Host $TestHost "is missing" (Get-Date) -ForegroundColor Red #-BackgroundColor White 
    } 
 
    If($Ping) 
    { 
     Write-Host $TestHost "is there" (Get-Date) -ForegroundColor Green #-BackgroundColor White 
     Get-Registry $Server 
    } 
}  
 
 
If ($UserSID -ne ""){ 
    $UsersProfileKey = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSID" 
    Write-Host $UsersProfileKey 
    
        ForEach ($Server in $Servers){ 
        Ping-Test $Server 
    } 
     
}