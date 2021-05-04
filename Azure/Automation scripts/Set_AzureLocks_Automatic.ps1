$TagName = "Automatically Lock Resource"
$TagValue = "yes"

#Azure Lock Settings
$LockName = "CannotDelete"
$LockType = "CanNotDelete" # Locktype value has to be specified as "CanNotDelete" or "ReadOnly"
$LockNotes = "This lock is created by Automation Account."

    #Connect with managed idenity
    "Logging in to Azure..."
    Connect-AzAccount -Identity

   <# 
    #Connect with Service Principal
    $connectionName = "AzureRunAsConnection"
try
{
    #Get the connection "AzureRunAsConnection"
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Connect-AzAccount `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}

catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
    #>
    
#Get Resource Groups with specified tag

$ResourceGroups = Get-AzResourceGroup | Where-Object {$_.Tags.Keys -match $TagName -and $_.Tags.Values -match $TagValue} 

#Setting Azure Lock
foreach($ResourceGroup in $ResourceGroups.ResourceGroupName) {

    $CheckLock = Get-AzResourceLock -ResourceGroupName $ResourceGroup
    if($CheckLock.Properties.level -eq $LockType) {
        #Write-Verbose "Azure Lock type Delete is already created on $ResourceGroup." -Verbose
        Write-output "Azure Lock type Delete is already created on $ResourceGroup."
        
    }
    else {
        New-AzResourceLock -ResourceGroupName $ResourceGroup -LockName $LockName -LockLevel $LockType -LockNotes $LockNotes -Force
        Write-output "Settings Delete Lock on ResourceGroup $ResourceGroup."
    }
      
       
}