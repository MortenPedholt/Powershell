<#
.DESCRIPTION
##*===============================================
##* START - DESCRIPTION
##*===============================================    
This script will "move" a your VM to another Vnet. It will copy your VM configuration and create a new VM into the selected Vnet.
Running this script will stop the VM that you will move!
If you want to move a Linux go down and change "-Windows" to "-Linux" under creation on OS Disk
Your pubic IP will be moved from your current NIC to the new one, same with NSG.

Script author: Morten Pedholt
Script created on: November 2019
Script edited date: NA
Script last edited by: NA
Script version: 1.0.0
##*===============================================
##* END - DESCRIPTION
##*===============================================
#>

##*===============================================
##* START - PARAMETERS
##*===============================================

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]    
    [string]$logpath = '',
    [Parameter(Mandatory=$false)]    
    [string]$modulename = 'Az',
    [Parameter(Mandatory=$true)]    
    [string]$OriginalVMname = '',
    [Parameter(Mandatory=$true)]    
    [string]$VMResouceGroup = '',
    [Parameter(Mandatory=$true)]    
    [string]$MoveToVnetName = '',
    [Parameter(Mandatory=$true)]    
    [string]$MoveToSubnetName = '',
    [Parameter(Mandatory=$true)]    
    [string]$NetworkResourceGroup = '',
    [Parameter(Mandatory=$true)]    
    [string]$NewVmName = ''
	
)
##*===============================================
##* END - PARAMETERS
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

 Start-Transcript -Path $logpath\Pedholtlab_$(get-date -f yyyy-MM-dd).txt -IncludeInvocationHeader -Append -Force -Verbose
    }else {
    Write-Host "No logpath is specificed in variables" -ForegroundColor Cyan
}
##*===============================================
##*  END - CHECK FOR LOGGIN IN SCRIPT
##*===============================================


##*===============================================
##*  START - CHECK IF REQUIRED MODULE IS INSTALLED
##*===============================================

#Check if the required module is installed, if not it will install and import the module.
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
##*  END - CHECK IF REQUIRED MODULE IS INSTALLED
##*===============================================

##*===============================================
##* START - SCRIPT BODY
##*===============================================
Write-Host "Loggin in.." -ForegroundColor Cyan
Login-AzAccount -ErrorAction Stop

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

#Get original VM configuration
Write-Host "Getting original vm configuration" -ForegroundColor Cyan
$Vm = Get-AzVM -Name $OriginalVMname -ResourceGroupName $VMResouceGroup
$CurrentNICConfig = $VM.NetworkProfile.NetworkInterfaces[0].Id | Get-AzNetworkInterface
$DataDisks = $Vm.StorageProfile.DataDisks

#Get Vnet
$Vnet = Get-AzVirtualNetwork -Name $MoveToVnetName -ResourceGroupName $NetworkResourceGroup

#Get Subnet
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $MoveToSubnetName -VirtualNetwork $Vnet

#IP Config to New NIC
$NewIPConfig = New-AzNetworkInterfaceIpConfig -Subnet $Subnet -Name "config1" -Verbose

#Create new NIC
Write-Host "Creating new NIC" -ForegroundColor Cyan
$NewNicName = $NewVmName + '_nic01'
$NewNic = New-AzNetworkInterface -Name $NewNicName -ResourceGroupName $VMResouceGroup -Location $vm.Location -IpConfiguration $NewIPConfig -Force -Verbose

#Attach NSG to new NIC
$GetCurrentNSGOnNIC = ($CurrentNICConfig).NetworkSecurityGroup.Id.Split('/') | select -Last 1 -ErrorAction SilentlyContinue
if ($GetCurrentNSGOnNIC) {
    Write-Host "There is a NSG attached to old NIC, moveing to new NIC" -ForegroundColor Cyan
        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $VMResouceGroup  -Name $GetCurrentNSGOnNIC
        $NIC = Get-AzNetworkInterface -ResourceGroupName $VMResouceGroup -Name $NewNicName
        $NIC.NetworkSecurityGroup = $nsg
        $NIC | Set-AzNetworkInterface
    }
else{
    Write-Host "There are no NSG Attached to old NIC" -ForegroundColor Cyan
}

#Check for public IP on old NIC
###
$CurrentNICConfig = $VM.NetworkProfile.NetworkInterfaces[0].Id | Get-AzNetworkInterface

$CheckForPublicIp =  (Get-AzNetworkInterface -ResourceGroupName $VMResouceGroup -Name $CurrentNICConfig.Name).IpConfigurations.PublicIpAddress
if ($CheckForPublicIp) {
    Write-Host "There is a public IP attached to original vm NIC, checking if its dynamic or static" -ForegroundColor Cyan
    #Check if Public IP is set to Static or Dynamic
        if ($PublicIpName) {
    
        $PublicIpAddress = (Get-AzPublicIpAddress -ResourceGroupName $VMResouceGroup -Name $publicIpName)
            if ($PublicIpAddress.PublicIpAllocationMethod -eq "dynamic") { 
            Write-Host "The Public IP is set to Dynamic! Your Public IP might change, when the VM gets shutdown" -ForegroundColor Cyan
            
            
    
            }
                else { 
                Write-Host "Public IP is set to Static" -ForegroundColor Cyan
         }
 
        }else {
    
}

}else{
    Write-Host "There is no public IP attached to original vm NIC" -ForegroundColor Cyan
}


#STOP VM
Write-Host "Stopping original VM" -ForegroundColor Cyan
Stop-AzVm -ResourceGroupName $VMResouceGroup -Name $Vm.Name -Force -Confirm:$false

#Create snapshot
Write-Host "Creating Snapshot of original OS Disk" -ForegroundColor Cyan
$VmOSDisk = $Vm.StorageProfile.OsDisk.Name
$Disk = Get-AzDisk -ResourceGroupName $VMResouceGroup -DiskName $VmOSDisk
$SnapshotName = $VmOSDisk + '_Snapshot01'
$SnapshotConfig =  New-AzSnapshotConfig -SourceResourceId $Disk.Id -CreateOption Copy -Location $Disk.Location
$NewSnapshot = New-AzSnapshot -Snapshot $SnapshotConfig -SnapshotName $SnapshotName -ResourceGroupName $VMResouceGroup


#Create new OS Disk based on Snapshot
Write-Host "Createing new OS disk, based on Snapshot" -ForegroundColor Cyan
$Snapshot = Get-AzSnapshot -ResourceGroupName $VMResouceGroup -SnapshotName $SnapshotName
$DiskConfig = New-AzDiskConfig -Location $Snapshot.Location -SourceResourceId $Snapshot.Id -CreateOption Copy
$NewOSDiskName = $NewVmName + '_OSDisk_01'
$Disk = New-AzDisk -Disk $DiskConfig -ResourceGroupName $VMResouceGroup -DiskName $NewOSDiskName


#Create New VM
Write-Host "Creating new VM in new Vnet" -ForegroundColor Cyan
$VmSize = $Vm.HardwareProfile.VmSize
$VirtualMachine = New-AzVMConfig -VMName $NewVmName -VMSize $VmSize
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -ManagedDiskId $Disk.Id -CreateOption Attach -Windows
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NewNic.Id
New-AzVM -VM $VirtualMachine -ResourceGroupName $VMResouceGroup -Location $Vm.Location
$NewVM = Get-AzVM -Name $NewVmName -ResourceGroupName $VMResouceGroup

#Move Data disk to new VM if exist
if ($DataDisks) {
    Write-Host "There is data disks attached to old vm, moving them to new vm" -ForegroundColor Cyan
    foreach ($Datadisk in $DataDisks) {
        Remove-AzVMDataDisk -VM $Vm -DataDiskNames $Datadisk.Name -Verbose
        Update-AzVM -ResourceGroupName $VMResouceGroup -VM $Vm -Verbose
        Add-AzVMDataDisk -VM $NewVM -Name $Datadisk.Name -ManagedDiskId $Datadisk.ManagedDisk.Id -Caching $Datadisk.Caching -Lun $Datadisk.Lun -DiskSizeInGB $Datadisk.DiskSizeGB -CreateOption Attach -Verbose
        Update-AzVM -ResourceGroupName $VMResouceGroup -VM $NewVM -Verbose
        Write-Host $DataDisk.Name "has been moved to new vm" -ForegroundColor Cyan

    }

}
else{
    Write-Host "There are no data disks attached to old VM" -ForegroundColor Cyan
}


#Move Public IP from old NIC and assing to new NIC, and associate it to new NIC
if ($PublicIpName) {
    Write-Host "There is public IP attached to old NIC" -ForegroundColor Cyan

        Write-Host "Removeing PublicIP from old NIC" -ForegroundColor Cyan
        $DiassociatePublicIP = Get-AzNetworkInterface -Name $CurrentNICConfig.Name -ResourceGroupName $VMResouceGroup
        $DiassociatePublicIP.IpConfigurations.publicipaddress.id = $null
        $DiassociatePublicIP | Set-AzNetworkInterface
        
        $AssociatePublicIP = Get-AzNetworkInterface -Name $NewNic.Name -ResourceGroupName $VMResouceGroup
        $AssociatePublicIP | Set-AzNetworkInterfaceIpConfig -Name ‘config1’ -PublicIPAddress $PublicIpAddress
        $AssociatePublicIP | Set-AzNetworkInterface
        Write-Host "Public IP has been moved to new NIC" -ForegroundColor Cyan

    
    }
    else {
    
}


#Delete old resources
 
Write-host "Would you like to delete the following old resources?" -ForegroundColor Cyan
Write-host $Vm.name -ForegroundColor Cyan
Write-host $VmOSDisk -ForegroundColor Cyan
Write-host $SnapshotName -ForegroundColor Cyan
Write-host $CurrentNICConfig.Name -ForegroundColor Cyan

$YesOrNo = Read-Host "Please enter your response (y/n)"
while("y","n" -notcontains $YesOrNo )
{
  $YesOrNo = Read-Host "Please enter your response (y/n)"
}
 
If ($YesOrNo -eq "y") {
Write-host "Deleteing old resources" -ForegroundColor Cyan
Remove-AzVM -ResourceGroupName $VMResouceGroup -Name $Vm.Name -Force -Confirm:$false -Verbose
Remove-AzDisk -ResourceGroupName $VMResouceGroup -DiskName $VmOSDisk -Force -Confirm:$false -Verbose
Remove-AzSnapshot -ResourceGroupName $VMResouceGroup -SnapshotName $SnapshotName -Force -Confirm:$false -Verbose
Remove-AzNetworkInterface -ResourceGroupName $VMResouceGroup -Name $CurrentNICConfig.Name -Force -Confirm:$false -Verbose
Write-host "old resources has now been deleted." -ForegroundColor Cyan

} else {
write-host "Not deleteing old resources" -ForegroundColor Cyan

}

#Disconnect Azure session
Write-Host "Disconnecting Azure account, end of script" -ForegroundColor Cyan
Disconnect-AzAccount




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

