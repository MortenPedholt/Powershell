Start-Transcript -Path c:\Windows\Logs\Software\WindowsUpdates.log

#search and list all missing updates
(New-Object -ComObject Microsoft.Update.ServiceManager).Services
$UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager
$UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
$Searcher.SearchScope = 1 # MachineOnly
$Searcher.ServerSelection = 2

$Criteria = "IsInstalled=0 and ISHidden=0 and Type='Software' and IsAssigned=1"
Write-Host('Searching Windows Updates...') -Fore Green
$SearchResult = $Searcher.Search($Criteria)
$Updates = $SearchResult.Updates

# For test
$refUpdates = $SearchResult.Updates

#Check if updates are not zero
IF ($Updates.Count -ge 1) {

    $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
    $Downloader = $UpdateSession.CreateUpdateDownloader()

    # Update required check
    $rebootRequired = $false

    Foreach ($Update in $Updates) {
        Try {
            If ($Update.Type -eq 1) {
                If (!($Update.IsDownloaded)) {
                $UpdatesToDownload.Add($Update) | Out-Null
                #$Update | Format-List -Property Title, DriverModel, DriverVerDate, Driverclass, DriverManufacturer,Type
                    Write-Host("Downloading Update '$($Update.Title)'")  -Fore Green 
                    $Downloader.Updates = $UpdatesToDownload
                    $Downloader.Download() | Out-Null
                } else {
                Write-host ("Update '$($Update.Title)' is already downloaded.")  -Fore Green 
                }

                Write-Host("Installing Update '$($Update.Title)'") -Fore Green
                $Installer = New-Object -ComObject Microsoft.Update.Installer
                $UpdatesToInstall.Add($Update) | Out-Null
                $Installer.Updates = $UpdatesToInstall
                $Result = $Installer.Install()

                   
                    If ($Result.RebootRequired) { $rebootRequired = $true } 
            }
        } Catch {
        #Skip update
        Write-host "Skip $($Update.Title)"
        }
    }

    If ($rebootRequired) { 
    Write-Host('Reboot required! please reboot now..') -Fore Red
    
    } else {
    
    Write-Host('No Reboot required') -Fore green
    }


   } Else {
    Write-Host "No updates found!" -ForegroundColor Green
}


Stop-Transcript