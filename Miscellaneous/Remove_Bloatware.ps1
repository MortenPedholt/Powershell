# This script is uninstalling preinstalled and provisioned Microsoft applications [BLOATWARE]
# 
# See link below, to get an overview of preinstalled and provisioned apps.
# https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10


#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

$AppList = "Microsoft.3DBuilder",
           "Microsoft.BingNews",
           "Microsoft.BingWeather",
           "Microsoft.FreshPaint",
           "Microsoft.Getstarted",
           "Microsoft.Messaging",
           "Microsoft.MicrosoftOfficeHub",
           "Microsoft.NetworkSpeedTest",
           "Microsoft.Office.OneNote",
           "Microsoft.Office.Sway",
           "Microsoft.People",
           "Microsoft.SkypeApp",
           "Microsoft.WindowsAlarms",
           "Microsoft.windowscommunicationsapps",
           "Microsoft.WindowsFeedbackHub",
           "Microsoft.WindowsMaps",
           "Microsoft.ZuneMusic",
           "Microsoft.ZuneVideo",
           "Microsoft.MicrosoftSolitaireCollection",
           "Microsoft.MixedReality.Portal",
           "Microsoft.OneConnect",
           "Microsoft.StorePurchaseApp",
           "Microsoft.Wallet",
           "Microsoft.Xbox.TCUI",
           "Microsoft.XboxApp",
           "Microsoft.XboxGameOverlay",
           "Microsoft.XboxGamingOverlay",
           "Microsoft.XboxIdentityProvider",
           "Microsoft.XboxSpeechToTextOverlay",
           "Microsoft.YourPhone",
           "Microsoft.GetHelp",
           "Microsoft.Microsoft3DViewer",
           "Microsoft.WindowsSoundRecorder",
           "Microsoft.XboxGameCallableUI",
           "SpotifyAB.SpotifyMusic"
           


                      
ForEach ($App in $AppList)
{
$AppFullName = (Get-AppxPackage $App).PackageFullName
$ProAppFullName = (Get-AppxProvisionedPackage -online | Where-Object {$_.Displayname -eq $App}).PackageName
    write-host $AppFullName
    Write-Host $ProAppFullName
    if ($AppFullName)
    {
    Write-Host "Removing package: $App"
    Remove-AppxPackage -AllUsers -package $AppFullName
    }
    else
    {
    Write-Host "Unable to find package: $App"
    }
    if ($ProAppFullName)
    {
    Write-Host "Removing provisioned package: $ProAppFullName"
    Remove-AppxProvisionedPackage -online -packagename $ProAppFullName
    }
    else
    {
    Write-Host "Unable to find provisioned package: $App"
    }
}

#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy restricted -Force 