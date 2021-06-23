
###VARIABLES start
###Enter user UPN that will be granted tenantcreator for the Windows Virtual Dekstop
$WVDTenantName = ""
$AzureADTenantID = ""
$RDSOwnerUserAssignment = ""
$ServicePrincipalAppID = ""

###VARIABLES start

#Connect Azure account
Connect-AzAccount -ErrorAction Stop

#Get Azure subscriptions
$Subscriptions = Get-AzSubscription
if ($Subscriptions.count -gt 1){
    Write-Host "There is more than one subscription, please enter your Azure subscription ID" -ForegroundColor Cyan
    $SelectSubscriptionID = Read-Host 'Enter your Subscription ID here'

}else {
    $SelectSubscriptionID = $Subscriptions.Id
}

# Select Azure subscription
Write-Host "Selecting subscription ID" $Subscriptions.Id -ForegroundColor Cyan
Set-AzContext -SubscriptionId $SelectSubscriptionID -ErrorAction Stop

#import WVD module
Import-Module -Name Microsoft.RDInfra.RDPowerShell

#Create WVD Tenant
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
New-RdsTenant -Name $WVDTenantName -AadTenantId $AzureADTenantID -AzureSubscriptionId $SelectSubscriptionID


#Add user to RDS Owner of the WVD tenant
New-RdsRoleAssignment -TenantName $WVDTenantName -SignInName $RDSOwnerUserAssignment -RoleDefinitionName "RDS Owner"

#Assign Service Principal as RDSOwner
New-RdsRoleAssignment -RoleDefinitionName "RDS Owner" -ApplicationId $ServicePrincipalAppID -TenantName $WVDTenantName