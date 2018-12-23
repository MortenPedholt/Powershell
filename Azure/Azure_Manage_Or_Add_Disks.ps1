################################# Add new disk to "Disks" in Azure #################################
<#
$rgname = "vmtest"
$location = "West Europe"
$disksizegb = "188"
$storagetype = "PremiumLRS"
$createoption = "Empty"
$diskname = "MyDataDisk0055"
$ostype = "Windows"


$diskconfig = New-AzureRmDiskConfig -Location $location -DiskSizeGB $disksizegb -AccountType $storagetype -OsType $ostype -CreateOption $createoption
New-AzureRmDisk -ResourceGroupName $rgname -DiskName $diskname -Disk $diskconfig

#>

################################# Add New Disk to "Disks" From storageaccount in Azure #################################
<#
$rgname = "vmtest"
$location = "West Europe"
$disksizegb = "128"
$storagetype = "PremiumLRS"
$createoption = "Import"
$diskname = "testdisk022qqq665"
$vhdurisource = "https://restroerscac.blob.core.windows.net/backupvm01-2e1177bd64ad45ac8f807a9e5e1d26ee/backupvm01-osdisk-20180705-085807.vhd"
$storageaccountid = "/subscriptions/5af551c7-57b1-485f-adea-417c40a581e8/resourceGroups/vmtest/providers/Microsoft.Storage/storageAccounts/restroerscac"


$diskconfig = New-AzureRmDiskConfig -SkuName $storagetype -Location $location -DiskSizeGB $disksizegb -CreateOption $createoption -StorageAccountId $storageaccountid -SourceUri $vhdurisource
$datadisk = New-AzureRmDisk -ResourceGroupName $rgname -DiskName $diskname -disk $diskconfig
#>

################################# Add New OSDisk to VM #################################

<#$rgname = "vmtest"
$vmname = "backupvm01"
$newosdisk = "osdtasddisk02"


$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmname 
$disk = Get-AzureRmDisk -ResourceGroupName $rgName -Name $newosdisk
Stop-AzureRmVM -ResourceGroupName $rgname -Name $vm.Name -Force
Set-AzureRmVMOSDisk -VM $vm -ManagedDiskId $disk.Id -Name $disk.Name 
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm
Start-AzureRmVM -Name $vm.Name -ResourceGroupName $rgname

#>


<#
################################# Add new DATADisk to VM #################################

$rgname = "vmtest"
$vmname = "backupvm01"
$location = "West Europe" 
$datadiskname = "datadiskvm001"
$disk = Get-AzureRmDisk -ResourceGroupName $rgname -DiskName $datadiskname

$vm = Get-AzureRmVM -Name $vmname -ResourceGroupName $rgname 

$vm = Add-AzureRmVMDataDisk -CreateOption Attach -Lun 3 -VM $vm -ManagedDiskId $disk.Id

Update-AzureRmVM -VM $vm -ResourceGroupName $rgName
#>