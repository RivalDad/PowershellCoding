<# 
 
.SYNOPSIS 
 
Retrieves DFSR backlog information for all Replication Groups and Connections from the perspective of the targeted server. 
 
 
 
.DESCRIPTION 
 
The Get-DFSRBacklog script uses Windows Management Instrumentation (WMI) to retrieve Replication Groups, Replication Folders, and Connections from the targeted computer.  
 
The script then uses this information along with MicrosoftDFS WMI methods to calculate the version vector and in turn backlog for each pairing. 
 
All of this information is returned in an array custom objects, that can be later processed as needed. 
 
The computername defaults to "localhost", or may be passed to the –computerName parameter. 
 
The parameters -RGName and -RFName may also be used to filter either or both results, but currently each parameter only accepts one single value. 
 
Checking multiple replication groups/folders will require either running the script again, or using the default to return all pairings. 
  
 
 
 
.EXAMPLE 
 
Output all of the DFSR backlog information from the local system into a sorted and grouped table. 
 
.\Get-DFSRBacklog.ps1 | sort-object BacklogStatus | format-table -groupby BacklogStatus 
 
 
 
.EXAMPLE 
 
Specify a DFSR target remotely, with a warning threshold of 100 
 
.\Get-DFSRBacklog.ps1 computername -WarningThreshold 100 
 
 
 
.EXAMPLE 
 
Specify a DFSR target remotely, only returning the data for a replication group named RepGroup1 
 
.\Get-DFSRBacklog.ps1 computername RepGroup1 
 
 
 
.NOTES 
 
You need to run this script with an account that has appropriate permission to query WMI from the remote computer. 
 
#> 
 
 
Param 
( 
    [string]$Computer = "localhost", 
    [string]$RGName = "", 
    [string]$RFName = "",  
    [int]$WarningThreshold = 50, 
    [int]$ErrorThreshold = 500 
) 
 
$DebugPreference = "SilentlyContinue" 
 
Function PingCheck 
{ 
    Param 
    ( 
        [string]$Computer = "localhost", 
        [int]$timeout = 120 
    ) 
    Write-host $computer 
    Write-debug $timeout 
    $Ping = New-Object System.Net.NetworkInformation.Ping 
    trap  
    { 
        Write-debug "The computer $computer could not be resolved."            
        continue 
    }  
    
    Write-debug "Checking server: $computer"        
    $reply = $Ping.Send($computer,$timeout) 
    Write-debug $reply 
    If ($reply.status -eq "Success")  
    { 
        Write-Output $True 
    } else { 
        Write-Output $False 
    }   
    
} 
 
Function Check-WMINamespace ($computer, $namespace) 
{ 
    $Namespaces = $Null 
    $Namespaces = Get-WmiObject -class __Namespace -namespace root -computername $computer | Where {$_.name -eq $namespace} 
    If ($Namespaces.Name -eq $Namespace) 
    { 
        Write-Output $True 
    } else { 
        Write-Output $False 
    } 
} 
 
Function Get-DFSRGroup ($computer, $RGName) 
{ 
    ## Query DFSR groups from the MicrosftDFS WMI namespace. 
    If ($RGName -eq "") 
    { 
        $WMIQuery = "SELECT * FROM DfsrReplicationGroupConfig" 
    } else { 
        $WMIQuery = "SELECT * FROM DfsrReplicationGroupConfig WHERE ReplicationGroupName='" + $RGName + "'" 
    } 
    $WMIObject = Get-WmiObject -computername $computer -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
    Write-Output $WMIObject 
} 
 
Function Get-DFSRConnections ($computer) 
{ 
    ## Query DFSR connections from the MicrosftDFS WMI namespace. 
    $WMIQuery = "SELECT * FROM DfsrConnectionConfig" 
    $WMIObject = Get-WmiObject -computername $computer -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
    Write-Output $WMIObject 
} 
 
 
Function Get-DFSRFolder ($computer, $RFname) 
{ 
    ## Query DFSR folders from the MicrosftDFS WMI namespace. 
    If ($RFName -eq "") 
    { 
        $WMIQuery = "SELECT * FROM DfsrReplicatedFolderConfig" 
    } else { 
        $WMIQuery = "SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicatedFolderName='" + $RFName + "'" 
    } 
    $WMIObject = Get-WmiObject -computername $computer -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
    Write-Output $WMIObject 
} 
 
 
Function Get-DFSRBacklogInfo ($Computer, $RGroups, $RFolders, $RConnections) 
{ 
   $objSet = @() 
    
   Foreach ($Group in $RGroups) 
   { 
        $ReplicationGroupName = $Group.ReplicationGroupName     
        $ReplicationGroupGUID = $Group.ReplicationGroupGUID 
            
        Foreach ($Folder in $RFolders)  
        { 
           If ($Folder.ReplicationGroupGUID -eq $ReplicationGroupGUID)  
           { 
                $ReplicatedFolderName = $Folder.ReplicatedFolderName 
                $FolderEnabled = $Folder.Enabled 
                Foreach ($Connection in $Rconnections) 
                { 
                    If ($Connection.ReplicationGroupGUID -eq $ReplicationGroupGUID)  
                    {     
                        $ConnectionEnabled = $Connection.Enabled 
                        $BacklogCount = $Null 
                        If ($FolderEnabled)  
                        { 
                            If ($ConnectionEnabled) 
                            { 
                                If ($Connection.Inbound) 
                                { 
                                    Write-debug "Connection Is Inbound" 
                                    $Smem = $Connection.PartnerName.Trim() 
                                    Write-debug $smem 
                                    $Rmem = $Computer.ToUpper() 
                                    Write-debug $Rmem 
                                     
                                    #Get the version vector of the inbound partner 
                                    $WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'" 
                                    $InboundPartnerWMI = Get-WmiObject -computername $Rmem -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
                                     
                                    $WMIQuery = "SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'" 
                                    $PartnerFolderEnabledWMI = Get-WmiObject -computername $Smem -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
                                    $PartnerFolderEnabled = $PartnerFolderEnabledWMI.Enabled              
                                     
                                    If ($PartnerFolderEnabled) 
                                    { 
                                        $Vv = $InboundPartnerWMI.GetVersionVector().VersionVector 
                                         
                                        #Get the backlogcount from outbound partner 
                                        $WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'" 
                                        $OutboundPartnerWMI = Get-WmiObject -computername $Smem -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
                                        $BacklogCount = $OutboundPartnerWMI.GetOutboundBacklogFileCount($Vv).BacklogFileCount   
                                    } 
                                } else { 
                                    Write-debug "Connection Is Outbound" 
                                    $Smem = $Computer.ToUpper()   
                                    Write-debug $smem                    
                                    $Rmem = $Connection.PartnerName.Trim() 
                                    Write-debug $Rmem 
                                     
                                    #Get the version vector of the inbound partner 
                                    $WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'" 
                                    $InboundPartnerWMI = Get-WmiObject -computername $Rmem -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
                                     
                                    $WMIQuery = "SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'" 
                                    $PartnerFolderEnabledWMI = Get-WmiObject -computername $Rmem -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
                                    $PartnerFolderEnabled = $PartnerFolderEnabledWMI.Enabled 
                                     
                                    If ($PartnerFolderEnabled) 
                                    { 
                                        $Vv = $InboundPartnerWMI.GetVersionVector().VersionVector 
                                         
                                        #Get the backlogcount from outbound partner 
                                        $WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'" 
                                        $OutboundPartnerWMI = Get-WmiObject -computername $Smem -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
                                        $BacklogCount = $OutboundPartnerWMI.GetOutboundBacklogFileCount($Vv).BacklogFileCount 
                                    }               
                                } 
                            } 
                        } 
                     
                        $obj = New-Object psobject 
                        $obj | Add-Member noteproperty ReplicationGroupName $ReplicationGroupName 
                        Write-debug $ReplicationGroupName 
                        $obj | Add-Member noteproperty ReplicatedFolderName $ReplicatedFolderName  
                        Write-debug $ReplicatedFolderName 
                        $obj | Add-Member noteproperty SendingMember $Smem 
                        Write-debug $Smem 
                        $obj | Add-Member noteproperty ReceivingMember $Rmem$ 
                        Write-debug $Rmem 
                        $obj | Add-Member noteproperty BacklogCount $BacklogCount 
                        if (!$BacklogCount)
                        {
                           $BacklogCount=0
                        }
                        Write-debug  $BacklogCount
                        $obj | Add-Member noteproperty FolderEnabled $FolderEnabled 
                        Write-debug $FolderEnabled 
                        $obj | Add-Member noteproperty ConnectionEnabled $ConnectionEnabled 
                        Write-debug $ConnectionEnabled 
                        $obj | Add-Member noteproperty Inbound $Connection.Inbound 
                        Write-debug $Connection.Inbound 
                         
                         
                        If ($BacklogCount -ne $Null) 
                        { 
                            If ($BacklogCount -lt $WarningThreshold)  
                            { 
                                $Backlogstatus = "Low" 
                            } 
                            elseif (($BacklogCount -ge $WarningThreshold) -and ($BacklogCount -lt $ErrorThreshold)) 
                            { 
                                $Backlogstatus = "Warning" 
                            } 
                            elseif ($BacklogCount -ge $ErrorThreshold) 
                            { 
                                $Backlogstatus = "Error" 
                            }  
                        } else { 
                            $Backlogstatus = "Disabled" 
                        } 
                     
                        $obj | Add-Member noteproperty BacklogStatus $BacklogStatus 
                     
                        $objSet += $obj 
                    } 
                }   
           }  
        } 
   } 
   Write-Output $objSet 
} 
 
 Write-debug "Computer = $Computer" 
 Write-debug "RFName = $RFName" 
Write-debug "RGName = $RGName" 
Write-debug "WarningThreshold = $WarningThreshold" 
Write-debug "ErrorThreshold = $ErrorThreshold" 



$Pingable = PingCheck $computer 
If ($Pingable) 
{ 
    $NamespaceExists = Check-WMINamespace $computer "MicrosoftDFS" 
    If ($NamespaceExists) 	
    { 
       Write-Host "Collecting RGroups from $computer" 
        $RGroups = Get-DFSRGroup $computer $RGName 
        Write-debug "Rgroups = $Rgroups" 
        Write-debug "Collecting RFolders from $computer" 
        $RFolders = Get-DFSRFolder $computer $RFName 
        Write-debug "RFolders = $RFolders" 
        Write-debug "Collecting RConnections from $computer" 
        $RConnections = Get-DFSRConnections $computer 
        Write-debug "RConnections = $RConnections" 
 
        Write-Host "Calculating Backlog from $computer" 
        $BacklogInfo = Get-DFSRBacklogInfo $Computer $RGroups $RFolders $RConnections 
        
        
 
#        Write-Output  
    } else { 
        Write-Error "MicrosoftDFS WMI Namespace does not exist on '$computer'.  Run locally on a system with the Namespace, or provide computer parameter of that system to run remotely." 
    } 
} else { 
    Write-Error "The computer '$computer' did not respond to ping." 
}





$ns=[wmiclass]'__namespace'
$sc=$ns.CreateInstance()
$sc.Name='nable'
$sc.Put()
$file="c:\temp\file1.txt"

if ((get-wmiobject -namespace "root/cimv2/nable" -list -EV namespaceError) | ? {$_.name -match "DFSRSummary"})
{
   
    $dbcount = New-Object system.Collections.ArrayList
    $testfolder=Get-WMIObject -namespace root/cimv2/nable -query "Select * From DFSRSummary"
    $rr=0;
    Get-WMIObject -namespace root/cimv2/nable -query "Select * From DFSRSummary" | foreach {$dbcount.Insert($rr, $_);$rr++ }

    $dbcnt=$dbcount.count
    if($dbcount.count -ge '1')
    {
        $testfolder | Remove-WMIObject
    }  

}
else
{
    

    if( ![string]::IsNullOrEmpty( $namespaceError[0] ) )
    {
    	add-content $file "ERROR accessing namespace: $namespaceError[0]"
    	RETURN
    }

    try 
    {

    $newClass = New-Object System.Management.ManagementClass `
        ("root\cimv2\nable", [String]::Empty, $null); 
        $newClass["__CLASS"] = "DFSRSummary"; 

    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ReplicationGroupName", [System.Management.CimType]::String, $false)
    $newClass.Properties["ReplicationGroupName"].Qualifiers.Add("Key", $true)

    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ReplicatedFolderNameAndID", [System.Management.CimType]::String, $false)
    $newClass.Properties["ReplicatedFolderNameAndID"].Qualifiers.Add("Key", $true)

    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ReplicatedFolderName", [System.Management.CimType]::String, $false)
    $newClass.Properties["ReplicatedFolderName"].Qualifiers.Add("Key", $true)

    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("SendingMember", [System.Management.CimType]::String, $false)
    $newClass.Properties["SendingMember"].Qualifiers.Add("Key", $true)
	
        $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ReceivingMember", [System.Management.CimType]::String, $false)
    $newClass.Properties["ReceivingMember"].Qualifiers.Add("Key", $true)
	
    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("BackLogCount", [System.Management.CimType]::UInt32, $false)
    $newClass.Properties["BackLogCount"].Qualifiers.Add("Key", $true)
	
    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("FolderEnabled", [System.Management.CimType]::Boolean, $false)
    $newClass.Properties["FolderEnabled"].Qualifiers.Add("Key", $true)
	
    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ConnectionEnabled", [System.Management.CimType]::Boolean, $false)
    $newClass.Properties["ConnectionEnabled"].Qualifiers.Add("Key", $true)
	
    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("Inbound", [System.Management.CimType]::Boolean, $false)
    $newClass.Properties["Inbound"].Qualifiers.Add("Key", $true)

    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("BackLogStatusText", [System.Management.CimType]::String, $false)
    $newClass.Properties["BackLogStatusText"].Qualifiers.Add("Key", $true)

    $newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("BackLogStatusCode", [System.Management.CimType]::UInt32, $false)
    $newClass.Properties["BackLogStatusCode"].Qualifiers.Add("Key", $true)
	
    $newClass.Put()
    }
    catch
    {
       add-content $file "ERROR creating WMI class: $_"
    }
    ######################################
}



  
   
$backlogtotal=0
$backlogcount=0
$isallenabled="True"
$isallfolderenabled="True"

if ($BacklogInfo)
{
    while ( $BacklogInfo.Count -gt $backlogtotal )
    {
        try 
        {
                $mb = ([wmiclass]"root/cimv2/nable:DFSRSummary").CreateInstance()

           if ($BacklogInfo[$Backlogtotal].BackLogCount)
            {    
                $mb.BackLogCount=$BacklogInfo[$backlogtotal].BackLogCount 
                $backlogcount=$backlogcount+$BacklogInfo[$backlogtotal].BackLogCount 
            }
            else 
            {    $mb.BackLogCount=0 }


                if ($BacklogInfo[$Backlogtotal].BackLogStatus)
                {    
                    $mb.BackLogStatusText=$BacklogInfo[$Backlogtotal].BackLogStatus
                    
                    if ($BacklogInfo[$Backlogtotal].BackLogStatus -eq "LOW")
                        {$mb.BackLogStatusCode=0 }
                    elseif ($BacklogInfo[$Backlogtotal].BackLogStatus -eq "DISABLED")
                        {$mb.BackLogStatusCode=1 }
                    elseif ($BacklogInfo[$Backlogtotal].BackLogStatus -eq "WARNING")
                        {$mb.BackLogStatusCode=2 }
                    elseif ($BacklogInfo[$Backlogtotal].BackLogStatus -eq "ERROR")
                        {$mb.BackLogStatusCode=3 }
                    else 
                    {
                        $mb.BackLogStatusText="ERROR"
                        $mb.BackLogStatusCode=3
                    }
                }
                else 
                {    
                    $mb.BackLogStatusText="ERROR"
                    $mb.BackLogStatusCode=3
                }

                if ($BacklogInfo[$Backlogtotal].ConnectionEnabled)
                    { $mb.ConnectionEnabled="True" }
                else
                    { 
                        $mb.ConnectionEnabled="False" 
                        $isallenabled="False"
                    }
               
                if ($BacklogInfo[$Backlogtotal].Inbound)
                    { $mb.Inbound="True" }
                else
                    { $mb.Inbound="False" }

                if ($BacklogInfo[$Backlogtotal].ReceivingMember)
                    { $mb.ReceivingMember=$BacklogInfo[$Backlogtotal].ReceivingMember }
                else
                    { $mb.ReceivingMember="ERROR" }
                
                if ($BacklogInfo[$Backlogtotal].ReplicatedFolderName)
                    { $mb.ReplicatedFolderName=$BacklogInfo[$Backlogtotal].ReplicatedFolderName }
                else
                    { $mb.ReplicatedFolderName="ERROR" }
                
                if ($BacklogInfo[$Backlogtotal].ReplicationGroupName)
                    { $mb.ReplicationGroupName=$BacklogInfo[$Backlogtotal].ReplicationGroupName }
                else
                    { $mb.ReplicationGroupName="ERROR" }
                
                if ($BacklogInfo[$Backlogtotal].SendingMember )
                    { $mb.SendingMember=$BacklogInfo[$Backlogtotal].SendingMember }
                else
                    { $mb.SendingMember="ERROR" }
                
                if ($BacklogInfo[$Backlogtotal].FolderEnabled)
                    { $mb.FolderEnabled=$BacklogInfo[$Backlogtotal].FolderEnabled }
                else
                    { 
                    $mb.FolderEnabled="False" 
                    $isallfolderenabled="False"
                    }
                
                $mb.Put() 
            }

        catch
        {
            add-content $file "ERROR creating a new instance: $_"
        }    
        $backlogtotal=$backlogtotal+1
    
    }


    try 
    {
        $mb = ([wmiclass]"root/cimv2/nable:DFSRSummary").CreateInstance()

        $mb.BackLogCount=$backlogcount
        $mb.BackLogStatusText="Summary"
        $mb.BackLogStatusCode=0
        $mb.ConnectionEnabled=$isallenabled
        $mb.Inbound="True"
        $mb.ReceivingMember="Summary"
        $mb.ReplicatedFolderName="Summary"
        $mb.ReplicatedFolderNameAndID="Summary"
        $mb.ReplicationGroupName="Summary"
        $mb.SendingMember="Summary"
        $mb.FolderEnabled=$isallfolderenabled
        $mb.Put() 
    }
    catch
    {
        add-content $file "ERROR creating a new instance: $_"
    }    
   
    
    
}
else
{
    
}

write-output "Number of Rows : " + $backlogtotal
