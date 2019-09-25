# This script is uninstalling preinstalled and provisioned Microsoft applications [BLOATWARE]
# 
# See link below, to get an overview of preinstalled and provisioned apps.
# https://docs.microsoft.com/en-us/windows/application-management/apps-in-windows-10


#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

$AppList = "46928bounde.EclipseManager",
           "ActiproSoftwareLLC.562882FEEB491",
           "AdobeSystemsIncorporated.AdobePhotoshopExpress",
           "D5EA27B7.Duolingo-LearnLanguagesforFree",
           "Microsoft.3DBuilder",
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
           "Microsoft.Print3D",
           "Microsoft.SkypeApp",
           "Microsoft.WindowsAlarms",
           "Microsoft.windowscommunicationsapps",
           "Microsoft.WindowsFeedbackHub",
           "Microsoft.WindowsMaps",
           "Microsoft.XboxApp",
           "Microsoft.ZuneMusic",
           "Microsoft.ZuneVideo"
                      
ForEach ($App in $AppList)
{
$AppFullName = (Get-AppxPackage $App).PackageFullName
$ProAppFullName = (Get-AppxProvisionedPackage -online | Where-Object {$_.Displayname -eq $App}).PackageName
    write-host $AppFullName
    Write-Host $ProAppFullName
    if ($AppFullName)
    {
    Write-Host "Removing package: $App"
    Remove-AppxPackage -package $AppFullName
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