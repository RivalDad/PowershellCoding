read-host "Whats the SID looking for"
$objSID = New-Object System.Security.Principal.SecurityIdentifier("$SID")
$objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
$objUser.Value