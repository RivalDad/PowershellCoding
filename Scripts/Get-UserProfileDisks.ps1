#outputs a report, and flags any files that have less than the minimum free space specified

$vhdxShare = "\\BSA-DEN-DC01\Profiles"
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
        $vhdxSize = [math]::Round($vhdxFile.FileSize/1GB,2)
        $vhdxTotalSize = [math]::Round($vhdxFile.Size/1GB,2)
        $vhdxSpaceFree = $vhdxTotalSize - $vhdxSize

        $vhdxSpaceInfo = New-Object -TypeName psobject
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name FilePath -Value $filePath
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name Size -Value $vhdxSize
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name TotalSize -Value $vhdxTotalSize
        $vhdxSpaceInfo | Add-Member -MemberType NoteProperty -Name FreeSpace -Value $vhdxSpaceFree
        $vhdxSpaceInfo | export-csv -path $reportPath -NoTypeInformation -Append

        if ($vhdxSpaceInfo.FreeSpace -lt $minimumFreeSpace){
            write-host -ForegroundColor Red "Only $vhdxSpaceFree GB left on $($vhdxFile.Path)"
        }

        #write-host "Grabbed info for $filePath"
      }
      catch {
      Write-host -ForegroundColor Red "Error pulling info for $filePath, user logged in?"
      }
      
}


#To update the size of the VHDX file -
#get the path to the users' vhdx file - $path
$path = "\\BSA-DEN-DC01\Profiles\UVHD-S-1-5-21-2482637767-3900665392-389218837-5129.vhdx"
#get-vhd -path $path | resize-vhd -Sizebytes 10GB
