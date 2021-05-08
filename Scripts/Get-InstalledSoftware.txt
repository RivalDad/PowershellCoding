<#
.Synopsis
a tech can run this when they're trying to get the list of installed software. 

.DESCRIPTION
     There are 3 parts to this process
    First make sure that you have the correct user and .vhdx file
    Then expand the drive
    Then mount the drive onto a server and expand the diskpartition 
.EXAMPLE
    Just run it. Don't get fancy.  
.NOTES
   This needs to be ran as an Admin. 
#>


Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table �AutoSize