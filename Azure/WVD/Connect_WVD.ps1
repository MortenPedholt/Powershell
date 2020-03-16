$ServicePrincipalAppID = Read-Host "Enter Serviceprincipal AppID"
$ServicePrincipalSecret = Read-Host "Enter Serviceprincipal Secret"
$ServicePrincipalTenantID = Read-Host "Enter Serviceprincipal TenantID"


$creds = New-Object System.Management.Automation.PSCredential($ServicePrincipalAppID, (ConvertTo-SecureString $ServicePrincipalSecret  -AsPlainText -Force))
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com" -Credential $creds -ServicePrincipal -AadTenantId $ServicePrincipalTenantID