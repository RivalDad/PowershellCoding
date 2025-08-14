# used for getting connected to Microsoft online services
<#
.Synopsis
   This script helps show how many of each license a client may have. 
.DESCRIPTION
   This function logs into O365 via powershell and reports back the amount of each of these 3 important license types. 
.EXAMPLE
    Just run it. Don't get fancy.  
.NOTES
   This needs to be ran as an Admin. You may have to edit the output path for the Download folder. If there's already a folder with the name, the script will execute within a minute. 
#>

$UserCredential = Get-Credential 
Connect-MsolService -credential $usercredential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session 



$url = 'https://prod-30.westus.logic.azure.com:443/workflows/82cff90c3e3140e8b51e6342e051709f/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=GKRz2L4TP686IQEvWZis1HLtfGTG_eipzbUU8hxLGqA'
        $Test = Get-MsolAccountSku | select AccountSkuId,ActiveUnits,labels,ConsumedUnits
        $Array = @()
        Foreach ($Tested in $Test)
        { 
            if ($Tested.AccountSkuId -like "*ENTERPRISEPACK*"){
                $Result = "" | Select AccountSkuId,ActiveUnits,labels,ConsumedUnits
                $Result.AccountSkuId = "ENTERPRISEPACK Licenses - "
                $Result.ActiveUnits = $Tested.ActiveUnits
                $Result.Labels = "Active vs. Consumed" 
                $Result.ConsumedUnits = $Tested.ConsumedUnits
                $array += $Result
                }elseif ($Tested.AccountSkuId -like "*EMS*"){
                $Result = "" | Select AccountSkuId,ActiveUnits,labels,ConsumedUnits
                $Result.AccountSkuId = "EMS - Licenses"
                $Active = $Tested.ActiveUnits 
                $Result.ActiveUnits = $Tested.ActiveUnits
                $Result.Labels = "Active vs. Consumed" 
                $Result.ConsumedUnits = $Tested.ConsumedUnits
                $array += $Result
                }elseif ($Tested.AccountSkuId -like "*ATP_ENTERPRISE*"){
                $Result = "" | Select AccountSkuId,ActiveUnits,labels,ConsumedUnits
                $Result.AccountSkuId = "ATP ENTERPRISE - Licesnses"
                $Result.ActiveUnits = $Tested.ActiveUnits
                $Result.Labels = "Active vs. Consumed" 
                $Result.ConsumedUnits = $Tested.ConsumedUnits
                $array += $Result
                }
        }
        $array
