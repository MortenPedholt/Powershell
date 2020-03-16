#Login WVD
$ServicePrincipalAppID = ""
$ServicePrincipalSecret = ""
$ServicePrincipalTenantID = ""

$creds = New-Object System.Management.Automation.PSCredential($ServicePrincipalAppID, (ConvertTo-SecureString $ServicePrincipalSecret  -AsPlainText -Force))
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $creds -ServicePrincipal -AadTenantId $ServicePrincipalTenantID

#Variables#
$tenant = "xxxxx"
$hostpoolname = "xxxxx"
$appgroupname = "xxxxx"
Desktop Application Group


get-RdsHostPool -TenantName $tenant -Name $hostpoolname 
get-RdsAppGroup -TenantName $tenant -HostPoolName $hostpoolname 

#Lav ny RDS APPGROUP NAVN
New-RdsAppGroup $tenant $hostpoolname $appgroupname -ResourceType "RemoteApp"

#Se hvilket app group der er publish på hostpoolnavn
Get-RdsAppGroup -TenantName $tenant -HostPoolName $hostpoolname -Name $appgroupname

#Se hvilket brugere der er tilknyttet appgroupnavnet i hostpoolen
Get-RdsAppGroupUser -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname

#List installed apps on WVD Desktop
Get-RdsStartMenuApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname | Out-GridView #| Where-Object{$_.friendlyName -like "remote desktop"}


#Tilføj Office programmer
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Word" -AppAlias "word"
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Excel" -AppAlias "excel"
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Outlook" -AppAlias "outlook"
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Powerpoint" -AppAlias "powerpoint"
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "OneNote 2016" -AppAlias "onenote2016"
#Tilføj Edge programmer
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Microsoft Edge" -AppAlias "microsoftedge"


#NAV Genveje
new-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Microsoft NAV" -FriendlyName "NAV" -AppAlias "microsoftdynamicsnav2013r2" -CommandLineSetting Require -RequiredCommandLine '-settings:"\\settings.config"'

#RDP genvej
New-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Remote Desktop Connection" -AppAlias "remotedesktopconnection"

#File Explorer
new-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "File Explorer" -FilePath "C:\Windows\explorer.exe"


#Ændre en remote app setting
set-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Microsoft Edge - test" -FriendlyName "Microsoft Edge - test" -AppAlias "microsoftedge"

#TIlføj bruger
Add-RdsAppGroupUser -TenantName  $tenant -HostPoolName kl-wvd-general-hostpool04 -AppGroupName "Allapps" -UserPrincipalName "username@domain.com"

#Fjern bruger adgang
Remove-RdsAppGroupUser -TenantName  $tenant -HostPoolName kl-wvd-general-hostpool04 -AppGroupName "Allapps" -UserPrincipalName "username@domain.com"

#Tilføj Remote APP med parameter
new-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Microsoft Edge - test" -FriendlyName "Microsoft Edge - test" -AppAlias "microsoftedge" -CommandLineSetting Require -RequiredCommandLine "https://google.dk"


get-RdsSessionHost -TenantName $tenant -HostPoolName $hostpoolname


#Remove RDS Remote APP
Remove-RdsRemoteApp -TenantName $tenant -HostPoolName $hostpoolname -AppGroupName $appgroupname -Name "Microsoft Edge - test"


#Set max sessions

Set-RdsHostPool -Name @hostpoolname -TenantName $tenant -DepthFirstLoadBalancer -MaxSessionLimit 4

#Get user sessions

Get-RdsUserSession -TenantName $tenant -HostPoolName $hostpoolname
#LOg brugersession af
Invoke-RdsUserSessionLogoff -TenantName $tenant -HostPoolName $hostpoolname -SessionHostName wvddevhp04-0.koncern.local -SessionId 2
Get-RdsUserSession -TenantName $tenant -HostPoolName $hostpoolname | Where-Object { $_.UserPrincipalName -eq "contoso\user1" } | Invoke-RdsUserSessionLogoff -NoUserPrompt

