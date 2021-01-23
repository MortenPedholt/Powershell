Start-Transcript -Path $env:APPDATA\Microsoft\OneDrive_FreeUpSpace.txt -IncludeInvocationHeader -Force -Verbose

#Locate OneDrive folders
$OneDriveConnections = Get-ChildItem 'HKCU:\SOFTWARE\SyncEngines\Providers\OneDrive' -Recurse

#Ending script if OneDrive folder dosent exist
if (-not $OneDriveConnections) {
Write-Verbose "There is not any OneDrive availiable ending script" -Verbose


} Else {

Write-Verbose "OneDrive folders located" -Verbose

#Find OneDrives folder paths and free up space
foreach ($OneDrive in $OneDriveConnections) {
#Find folder path
$OneDriveName = $OneDrive.PSChildName
$OneDrivepath = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\SyncEngines\Providers\OneDrive\$OneDriveName" -Name "MountPoint"


Write-Verbose "Free up space in OneDrive location $OneDrivepath " -Verbose
#Locates downloaded files and releases them
$DownloadedFiles = Get-childitem $OneDrivepath -Force -File -Recurse | where Attributes -eq 'Archive, ReparsePoint'
foreach ($File in $DownloadedFiles) {
Write-Verbose "Releasing $($File.FullName)" -Verbose
attrib.exe $File.fullname +U -P /s
}

#Locates always available files and releases them
$AlwaysAvailiableFiles = Get-childitem $OneDrivepath -Force -File -Recurse | where Attributes -eq '525344'
foreach ($File in $AlwaysAvailiableFiles) {
Write-Verbose "Releasing $($File.FullName)" -Verbose
attrib.exe $File.fullname +U -P /s

}


}



}


stop-transcript