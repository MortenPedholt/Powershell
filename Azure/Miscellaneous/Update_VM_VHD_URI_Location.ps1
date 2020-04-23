#Recently tested fully with a later version of the Azure PowerShell module - Install-Module AzureRM -RequiredVersion 4.4.1

#Switch vhd file on an azure VM


#region Logon to Azure
Login-AzAccount

$subscription = Get-AzSubscription | Out-GridView -PassThru
Select-AzSubscription -SubscriptionId $subscription.Id
#endregion

# Variables for YOu to fill in
$ResourceGroup = 'RGName' # resource group name to contain the 
$VMname = 'VMName' # name of the VM you want to swap out the OS disk

#Get the VM config to a variable
$VM = Get-AzVM -Name $VMname -ResourceGroupName $ResourceGroup

#Stop and deallocate the VM
Stop-AzVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Force

#swap out the OS disk using the VM variable
$VM.StorageProfile.OsDisk.Vhd.Uri = 'https://xxxxxxx.blob.core.windows.net/vhds/xxxxx-V1.vhd'

#Update the VM configuration
Update-AzVM -VM $VM -ResourceGroupName $ResourceGroup