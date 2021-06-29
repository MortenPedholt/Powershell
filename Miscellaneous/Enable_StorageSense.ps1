## Enable Storage Sense
## Ensure the StorageSense key exists
$key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense"
If (!(Test-Path "$key")) {
    New-Item -Path "$key" | Out-Null
}
If (!(Test-Path "$key\Parameters")) {
    New-Item -Path "$key\Parameters" | Out-Null
}
If (!(Test-Path "$key\Parameters\StoragePolicy")) {
    New-Item -Path "$key\Parameters\StoragePolicy" | Out-Null
}

## Set Storage Sense settings
## Enable Storage Sense
Write-Host "Enabling Storage Sense" -ForegroundColor Cyan
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "01" -Type DWord -Value 1

## Set 'Run Storage Sense' to Every day
Write-Host "Setting storage sense to run every day" -ForegroundColor Cyan
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "2048" -Type DWord -Value 1

## Enable 'Delete temporary files that my apps aren't using'
Write-Host "Enable Deleting temporary files" -ForegroundColor Cyan
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "04" -Type DWord -Value 1

## Set 'Delete files in my recycle bin if they have been there for over' to 30 days
Write-Host "Set Delete files in recycle bin to 30 days" -ForegroundColor Cyan
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "08" -Type DWord -Value 1
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "256" -Type DWord -Value 30

## Set 'Delete files in my Downloads folder if they have been there for over' to 30 days
Write-Host "Set Delete files in download fodler to 30 days" -ForegroundColor Cyan
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "32" -Type DWord -Value 1
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "512" -Type DWord -Value 30

## Set value that Storage Sense has already notified the user
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "StoragePoliciesNotified" -Type DWord -Value 1

## Enable Storage Sense
Write-Host "Enabling Cloud Policy" -ForegroundColor Cyan
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "CloudfilePolicyConsent" -Type DWord -Value 1

$OneDriveKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy\*OneDrive*"
If (!(Test-Path "$OneDriveKey")) {
    write-host "OneDrive is not configured, ending script" -ForegroundColor Cyan
}
else {
    
    #Check if StorageSense is enabled

    
    write-host "OneDrive is configured, setting storage sense settings" -ForegroundColor Cyan
    #Enable Storage Sense for Onedrive
    Set-ItemProperty -Path "$OneDriveKey" -Name "02" -Type DWord -Value 1
    
    #Set content to be online-only after x day
    Set-ItemProperty -Path "$OneDriveKey" -Name "128" -Type DWord -Value 60


}
