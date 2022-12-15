<#
.DESCRIPTION
##*===============================================
##* START - DESCRIPTION
##*===============================================    

Script author: Morten Pedholt
Script created on: November 2019
Script edited date: April 2020
Script last edited by: Morten Pedholt
Script version: 1.0.0
##*===============================================
##* END - DESCRIPTION
##*===============================================

#>


##*===============================================
##* START - VARIABLES
##*===============================================

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]    
    [string]$modulename = 'AzureAD',
    [Parameter(Mandatory=$false)]    
    [string]$logpath = $env:SystemDrive + '\Scriptlogs'
	
)
##*===============================================
##* END - VARIABLES
##*===============================================


##*===============================================
##* START - CHECK FOR LOGGIN IN SCRIPT
##*===============================================

#Start transcript if logpath is defined
if ($logpath) {
    If(!(test-path $logpath)) {
            New-Item -ItemType Directory -Force -Path $logpath  -Verbose

    } else{
        Write-Host "$logpath Directory already exist" -ForegroundColor Cyan
        
    }

 Start-Transcript -Path $logpath\TemplateScripts_$(get-date -f yyyy-MM-dd).txt -IncludeInvocationHeader -Append -Force -Verbose
    }else {
    Write-Host "No logpath is specificed in variables" -ForegroundColor Cyan
}
##*===============================================
##*  END - CHECK FOR LOGGIN IN SCRIPT
##*===============================================


##*===============================================
##*  START - CHECK FOR MODULE IN SCRIPT
##*===============================================

#Check if the required module is installed is installed, if not it will install and import the module.
if ($modulename) {
    $checkmodule = Get-Module -ListAvailable | Where-Object { $_.Name -like $modulename } -Verbose
    if($checkmodule) {
    Write-Host "$modulename is already installed" -ForegroundColor Cyan
    Import-Module $checkmodule.Name
    }
    Else{
    Write-Host "$modulename is not installed, installing $modulename module" -ForegroundColor Green
    Install-Module $modulename -AllowClobber -Verbose
    Import-Module $modulename
    }

} else {
    Write-Host "No module requirements is specificed in variables" -ForegroundColor Cyan
}

##*===============================================
##*  END - CHECK FOR MODULE IN SCRIPT
##*===============================================

##*===============================================
##* START - SCRIPT BODY
##*===============================================

#Connect to AzureAD
Connect-AzureAD


#Set password to never expire
[INT]$userCount = Read-Host "Enter Number of users"
$Domain = Read-Host "Enter Domain"
$users = @()


1..$userCount | ForEach-Object {
    $UserPrincipalName = Read-Host "Enter Username"
    #$FirstName = Read-Host "Enter the first name of the employee"
    #$LastName = Read-Host "Enter the last name of the employee"
    #[INT]$empid = Read-Host "Enter the employee number"
    #$group = Read-Host "Enter the group name"
    #$homedrive = Read-Host "Enter the home drive"   

    $NewHire = @{}
    #$NewHire.Name = $FirstName
    #$NewHire.Empid = $empid
    #$NewHire.LastName = $LastName
    $NewHire.UserPrincipalName = $UserPrincipalName + "@$Domain"

    $Objectname = New-Object PSobject -Property $NewHire

    $users += $Objectname
}



foreach ($user in $users){

Write-host "Are you sure you would like to set password to never expire for" $user.UserPrincipalName"?"
$YesOrNo = Read-Host "Please enter your response (y/n)"
while("y","n" -notcontains $YesOrNo )
{
  $YesOrNo = Read-Host "Please enter your response (y/n)"
}
 
If ($YesOrNo -eq "y") {
$UserObject = Get-AzureADUser -Filter "UserPrincipalName eq '$user'"
Write-host "setting user password to never expire for" $user.UserPrincipalName -ForegroundColor Cyan
Set-AzureADUser -ObjectId $UserObject.ObjectId -PasswordNeverExpires $true
Get-AzureADUser -ObjectId $UserObject.ObjectId | Select-Object UserPrincipalName, PasswordNeverExpires

} else {
write-host "Not changeing anything for" $user.UserPrincipalName -ForegroundColor Red
write-host "If PasswordNeverExpires is displayed as TRUE, it was set before running this script" -ForegroundColor Red
Get-AzureADUser -ObjectId $UserObject.ObjectId | Select-Object UserPrincipalName, PasswordNeverExpires
}

}

##*===============================================
##* END - SCRIPT BODY
##*===============================================


#Stop Transcript if it's startet
try{
    stop-transcript | out-null
  }
  catch [System.InvalidOperationException]{}


##*===============================================
##* END - CHECK FOR LOGGIN IN SCRIPT
##*===============================================
