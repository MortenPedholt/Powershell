###VARIABLES start
###Enter user UPN that will be granted tenantcreator for the Windows Virtual Dekstop
$Username = "username@domain.com"
###VARIABLES start

#Connect to AzureAD
$AzureADContext = Connect-AzureAD -ErrorAction Stop

#Grant permissions to Windows Virtual Desktop Server App
Start-Process "https://login.microsoftonline.com/$($AzureAdContext.TenantID)/adminconsent?client_id=5a0aa725-4958-4b0c-80a9-34562e23f3b7&redirect_uri=https%3A%2F%2Frdweb.wvd.microsoft.com%2FRDWeb%2FConsentCallback"

#Grant permissions to Windows Virtual Desktop Client App
Start-Process "https://login.microsoftonline.com/$($AzureAdContext.TenantID)/adminconsent?client_id=fa4345a4-a730-4230-84a8-7d9651b86739&redirect_uri=https%3A%2F%2Frdweb.wvd.microsoft.com%2FRDWeb%2FConsentCallback"

#Assign tenant creator in Windows Virtual Dekstop Enterprise Application
$App_name = "Windows Virtual Desktop"
$App_role_name = "TenantCreator"

$User = Get-AzureADUser -ObjectId "$Username"
$Sp = Get-AzureADServicePrincipal -Filter "displayName eq '$App_name'"
$AppRole = $sp.AppRoles | Where-Object { $_.DisplayName -eq $App_role_name }

New-AzureADUserAppRoleAssignment -ObjectId $User.ObjectId -PrincipalId $User.ObjectId -ResourceId $Sp.ObjectId -Id $AppRole.Id

#Create Service Principal to manage WVD environment
#$aadContext = Connect-AzureAD
$svcPrincipal = New-AzureADApplication -AvailableToOtherTenants $true -DisplayName "Windows Virtual Desktop Svc Principal"
$svcPrincipalCreds = New-AzureADApplicationPasswordCredential -ObjectId $svcPrincipal.ObjectId

Write-Host "Service Principal Secret:" $svcPrincipalCreds.Value -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Principal AppID:" $svcPrincipal.AppId -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Principal TenantID:" $AzureADContext.TenantId.Guid -ForegroundColor Cyan
Write-Host ""
Write-Host "Remeber to save Service Principal secret, it will not be displayed again!!" -ForegroundColor Cyan

#Disconnect Azure AD
Disconnect-AzureAD