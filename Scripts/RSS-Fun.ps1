#Fill list of articles
$siteRSS = @()
$siteRSS += Invoke-RestMethod -Uri 'https://blogs.technet.microsoft.com/heyscriptingguy/feed/' | Select-Object -First 3
$siteRSS += Invoke-RestMethod -Uri 'https://mikefrobbins.com/feed/' | Select-Object -First 3
$siteRSS += Invoke-RestMethod -Uri 'http://feeds.arstechnica.com/arstechnica/index/' | Select-Object -First 3
$siteRSS += Invoke-RestMethod -Uri 'http://feeds.arstechnica.com/arstechnica/business/' | Select-Object -First 3

#Enumerate articles in list
$siteRSS | ForEach-Object -Begin {$i = -1} -Process {
    $i++
    "{0:D0}. {1} [{2}]" -f $i, $_.title, $_.pubdate
}

#Count articles
$articles = $siteRSS.Count
#Account for array offset
$articles = $articles - 1
#Declare valid range for $selection ([0..n])
$selectionNum = 0..$articles

Write-Host -ForegroundColor Yellow 'Select an article 0 -'$articles':'

$selection = Read-Host
if($selection -notin $selectionNum){
    do{
        $selection = $null
        Write-host -ForegroundColor Yellow 'Invalid selection'
        Write-Host -ForegroundColor Yellow 'Select an article 0 -'$articles':'
        $selection = Read-Host
    }
    until ($selection -in $selectionNum)
}

$selection = $siteRSS[$selection]
$selection = $selection.link

Start-Process "$selection"