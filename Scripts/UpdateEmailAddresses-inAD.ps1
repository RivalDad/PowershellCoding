Import-Module ActiveDirectory
$userlist = import-csv "C:\temp\userlist.csv"

foreach ($i in $userlist){
    $username = $i.UserDisplayName
    $UserPrincipalName = $i.UserPrincipalName
    $userinfo = Get-ADUser -Filter "Name -eq '$username'" -Properties mail,givenName,sn,proxyAddresses
    $list = New-Object System.Collections.ArrayList
   foreach($address in $userinfo.proxyaddresses) {

      $newPrimaryMail = $i.Appemail.tolower()
      $prefix = $address.Split(":")[0]
      $mail = $address.Split(":")[1]
   
      if ($mail.ToLower() -eq $newPrimaryMail.ToLower()) {
        $address = "SMTP:" + $mail.tolower()
      }
      else {
          $address = $prefix + ":" + $mail.ToLower()
      }
      $list.Add($address)
   }
   Get-ADUser -Filter "Name -eq '$username'" | Set-ADUser -replace @{ProxyAddresses=$list -split ","}
}
