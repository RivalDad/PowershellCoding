
<#
.Synopsis
Run this if a user is having trouble with their virtual Remote desktop profiles. Problems include reports of 'No disk space'
   outputs a report, and flags any files that have less than the minimum free space specified

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

$vhdxShare = "\\Location\To\Profiles"
#path to save report to
$reportPath = "C:\DoNotBackup\vhdreport.csv"
#script will tell you if there's less than this amount of space in GB on any vhdx file
$minimumFreeSpace = 2


#needs HyperV role installed
if((Get-WindowsFeature -Name Hyper-V).InstallState -ne "Installed"){
    write-host "Hyper-V Feature missing, it is required for this script"
    exit
}

write-host "Pulling VHDX report..."
Get-ChildItem $vhdxShare -recurse | Where-Object {$_.Extension -eq ".vhdx" -and $_.Name -ne "UVHD-template.vhdx"} | ForEach-Object {
      $filePath = $_.VersionInfo.FileName
      try{
        $vhdxFile = get-vhd -path $filePath -ErrorAction Stop
        $vhdxSize = [math]::Round($vhdxFile.FileSize/1GB,2) # Calculate the size of the VHDX file in GB, rounded to 2 decimal places
        $vhdxTotalSize = [math]::Round($vhdxFile.Size/1GB,2) # Calculate the total size of the VHDX file in GB, rounded to 2 decimal places
        $vhdxSpaceFree = $vhdxTotalSize - $vhdxSize # Calculate the free space available in the VHDX file

        # Create a new PSObject to store VHDX space information
        $vhdxSpaceInfo = New-Object -TypeName psobject
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name FilePath -Value $filePath # Add the file path to the object
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name Size -Value $vhdxSize # Add the VHDX size to the object
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name TotalSize -Value $vhdxTotalSize # Add the total size to the object
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name FreeSpace -Value $vhdxSpaceFree # Add the free space to the object

        # Export the VHDX space information to a CSV file, appending to the existing report
        $vhdxSpaceInfo | export-csv -path $reportPath -NoTypeInformation -Append

        # Check if the free space is below the minimum threshold and display a warning if true
        if ($vhdxSpaceInfo.FreeSpace -lt $minimumFreeSpace){
            write-host -ForegroundColor Red "Only $vhdxSpaceFree GB left on $($vhdxFile.Path)"
        }

        # Catch any errors that occur during the process and display an error message
        catch {
            Write-host -ForegroundColor Red "Error pulling info for $filePath, user logged in?"
        }
      
}


#To update the size of the VHDX file -
#get the path to the users' vhdx file - $path
$path = "\\Location\To\Profiles"\UVHD-S-1-5-21-2482637767-3900665392-389218837-5129.vhdx"
#get-vhd -path $path | resize-vhd -Sizebytes 10GB

