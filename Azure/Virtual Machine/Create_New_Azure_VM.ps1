# type in information: 
$LocationName = "westeurope" # should match
$ResourceGroupName = "test-rg1" # should match
$VMName = "MyVM"
$VNETName = "VNET" # should match
$SUBNETName = "Subnet" # should match
$SubnetAddressPrefix = "10.1.0.0/25" # should match
$VnetAddressPrefix = "10.1.0.0/24" # should match

# edit size of VM:
$VMSize = "Standard_DS3_v2"

# Backup policy
$backuppolicy = "DefaultPolicy"

# edit server version:
$PublisherName = "MicrosoftWindowsServer"
$Offer = "WindowsServer"
$Skus = "2012-R2-Datacenter"

# data disks
$Datadiskname01 = "$VMName-DataDisk01"
$DiskSizeGB = "127"
$SKU = "Premium_LRS"

# do nothing 
$OSdiskname = "$vmName-OSDISK"
$ComputerName = "$VMName"
$NICName = "$vmName-nic"
$VMNSG = "$vmName-NSG"
$ASName = "$vmName-AS"
$cred = Get-Credential

# create NSG for VM:
New-AzNetworkSecurityGroup -Name $VMNSG -ResourceGroupName $ResourceGroupName -Location $locationName
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $VMNSG

# creates network and assign nic and NSG to subnet:
$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet -Force
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -NetworkSecurityGroupId $nsg.Id

# create availability set 
New-AzAvailabilitySet -Location $LocationName -Name $ASName -ResourceGroupName $ResourceGroupName -Sku aligned -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2
$AvailabilitySet = Get-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $ASName

# create data disk 
$vmDataDisk01Config = New-AzDiskConfig -SkuName $SKU -Location $LocationName -CreateOption Empty -DiskSizeGB $DiskSizeGB
$vmDataDisk01 = New-AzDisk -DiskName $Datadiskname01 -Disk $vmDataDisk01Config -ResourceGroupName $ResourceGroupName

# set VM config
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet.Id
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $cred
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $Offer -Skus $Skus -Version latest
$VirtualMachine = Add-AzVMDataDisk -VM $VirtualMachine -Name $Datadiskname01 -CreateOption Attach -ManagedDiskId $vmDataDisk01.Id -Lun 0
Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -CreateOption fromImage

# edit if bootdiagnotics is nedded 
Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine 

# create VM
New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine

# backup VM 

$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $backuppolicy
Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $ResourceGroupName -Name $VMName -Policy $policy
