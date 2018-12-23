#This script will make any files "cloud-only" in your onedrive.
#NOTE! in windows version 1809 they have added a build-in feature in windows that allows you to do this withour script


#Change this to your own Company onedrive
##################################################
$onedrivelocation = "\OneDrive - mycompany"
##################################################
get-childitem $env:userprofile$onedrivelocation -Force -File -Recurse |
where Attributes -eq 'Archive, ReparsePoint' |
foreach {
    attrib.exe $_.fullname +U -P /s
}