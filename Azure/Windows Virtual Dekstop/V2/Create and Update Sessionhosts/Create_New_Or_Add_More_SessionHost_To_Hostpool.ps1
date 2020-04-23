##*===============================================
##* START - PARAMETERS
##*===============================================
$Location = ""
$VMSize = ""

$VMNameRG = ""

$VirtualNetworkName = ""
$VirtualNetworkNameRG = ""
$SubnetName = ""

$ImageName = ""

$Cred = (Get-Credential)

##*===============================================
##* END - PARAMETERS
##*===============================================

##*===============================================
##* START - SCRIPT BODY
##*===============================================


#Login and choose Azure subscription
    Write-Host "Loggin in.." -ForegroundColor Cyan
    Login-AzAccount -ErrorAction Stop

    #Get Azure subscriptions
    $Subscriptions = Get-AzSubscription
    if ($Subscriptions.count -gt 1) {
        Write-Host "There is more than one subscription, please enter your Azure subscription ID" -ForegroundColor Cyan
        $SelectSubscriptionID = Read-Host 'Enter your Subscription ID here'

    }
    else {
        $SelectSubscriptionID = $Subscriptions.Id
    }

    # Select Azure subscription
    Write-Host "Selecting subscription ID" $Subscriptions.Id -ForegroundColor Cyan
    Set-AzContext -SubscriptionId $SelectSubscriptionID -ErrorAction Stop



#Define How many VM and prefix 
[INT]$VMCount = Read-Host "Enter Number of VMs"

$VMPrefixName = Read-Host "Enter VM prefix name - NOTE!: character limit is 12"
while ($VMPrefixName.Length -gt 12 ) {
    Write-Host "Name is longer than 12 characters" -ForegroundColor Cyan
    $VMPrefixName = Read-Host "Enter VM prefix name - NOTE!: character limit is 12"
}


#Check for quota limit in deployment location
$RegionalVCpu = Get-AzVMUsage -Location $Location | Where-Object { $_.Name.Value -eq "cores" }
$RegionalCoreCurrentValue = $RegionalVCpu.CurrentValue
$RegionalCoreLimit = $RegionalVCpu.Limit

$VMSizeVCpu = Get-AzVMSize -Location $Location | Where-Object { ($_.Name -eq $VMSize) }
$NumberOfCores = $VMSizeVCpu.NumberOfCores

$TotalCores = $NumberOfCores * $VMCount + $RegionalCoreCurrentValue
if ($TotalCores -gt $RegionalCoreLimit) {
    write-host "Your subscription VCore quota is not high enough in $Location, your current limit is $RegionalCoreLimit" -ForegroundColor Cyan
    write-host "You will need to have a total of $TotalCores VCores in $location to continue" -ForegroundColor Cyan
    Write-Host "Ending script" -ForegroundColor Cyan
    Break
    
}else {
    write-host "There is enough VCores in your Subscription" -ForegroundColor Cyan
}

#############TODO###########
############################
############################
############################
#$VMSizeVCpu = Get-AzVMSize -Location $Location | Where-Object { ($_.Name -eq $VMSize) }
#$VMVCpu = Get-AzVMUsage -Location $Location #| Where-Object { $_.Name -contains "Standard" }
#$RegionalVCpu = Get-AzVMUsage -Location $Location | Select-Object @{label = "Name"; expression = { $_.name.Value } }, currentvalue, limit
#Get-AzVmssSku  $VMSize
#$VMSizeVCpu = Get-AzVMUsage -Location $Location | Where-Object { $_.Name.Value -eq $VMSize }
#$VMSizeVCpu = Get-AzVMUsage -Location $Location | Select-Object @{label = "Name"; expression = { $_.name.Value } }, currentvalue, limit | Where-Object { $_.Name.Value -like "Standard" }

#############TODO###########
############################
############################
############################

$VMS = 1..$VMCount

foreach ($VM in $VMS) {
    $VMName = "$VMPrefixName-$VM"

    #Check if VM Name already exist
    $CheckVMName = Get-AzVM -Name $VMName
    
    while ($VMName -eq $CheckVMName.Name ) {
        Write-Host "$VMName already exist adding one number to the name" -ForegroundColor Cyan
        $VM++
        $VMName = "$VMPrefixName-$VM"
        $CheckVMName = Get-AzVM -Name $VMName

    }
    
    Write-Host "Starting workflow to add VM $VMName" -ForegroundColor Cyan

    #Create if resourcegroup exists
    $CheckVMNameRG = Get-AzResourceGroup -Name $VMNameRG -ErrorAction SilentlyContinue
    if (!$CheckVMNameRG) {
        Write-Host "ResourceGroup $VMNameRG does not exist. Creating ResourceGroup $VMNameRG" -ForegroundColor Cyan
        if (!$Location) {
            $Location = Read-Host "resourceGroupLocation";
        }
        Write-Host "ResourceGroup $VMNameRG is created in location $Location" -ForegroundColor Cyan
        New-AzResourceGroup -Name $VMNameRG -Location $Location
    }
    else {
        Write-Host "ResourceGroup $VMNameRG Already Exist" -ForegroundColor Cyan
    }
   
    #Create NIC to new VM
    Write-Host "Creating NIC to VM $VMName" -ForegroundColor Cyan
    $Vnet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName  $VirtualNetworkNameRG
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $Vnet
    $NewIPConfig = New-AzNetworkInterfaceIpConfig -Subnet $Subnet -Name "config1" -Verbose
    $NewNic = New-AzNetworkInterface -Name "$($VMName)-nic" -ResourceGroupName $VMNameRG -Location $Location -IpConfiguration $NewIPConfig -Force -Verbose

    #Create Availability set
    Write-Host "Check if Availability already exist" -ForegroundColor Cyan
    $CheckAvilabilitySet = Get-AzAvailabilitySet -Name "$($VMPrefixName)-availabilityset"
    if ($CheckAvilabilitySet) {
        Write-Host "Availabilityset already exsist for this VM Prefix, using that for WVD VMS" -ForegroundColor Cyan
        $AvilabilitySet = $CheckAvilabilitySet

    }
    else {
        Write-Host "No exsiting Availability set, creating one named $VMPrefixName-availabilityset" -ForegroundColor Cyan
        $AvilabilitySet = New-AzAvailabilitySet -Name "$($VMPrefixName)-availabilityset" -ResourceGroupName $VMNameRG  -Location $Location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 5 -Sku "Aligned"

    }

    #Get Custom Image and Create new VM
    Write-Host "Getting information about custom image.." -ForegroundColor Cyan
    $imageversion = Get-AzImage | Where-Object { $_.Name -eq $ImageName }

    Write-Host "Set VM configuration.." -ForegroundColor Cyan

    $VMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetId $AvilabilitySet.Id -LicenseType "Windows_Client"
    $VMConfig = Set-AzVMOperatingSystem -VM $VMConfig -Windows -ComputerName $VMName -Credential $Cred
    $VMConfig = Set-AZVMBootDiagnostic -VM $VMConfig -Disable
    $VMConfig = Set-AzVMSourceImage -VM $VMConfig -Id $imageversion.id
    $VMConfig = Add-AzVMNetworkInterface -VM $VMConfig -Id $NewNic.Id
    $VMConfig = Set-AzVMOSDisk -VM $VMConfig -Name "$($VMName)-osdisk" -DiskSizeInGB "127" -StorageAccountType "StandardSSD_LRS" -CreateOption "Fromimage"
    Write-Host "Creating VM $VMName" -ForegroundColor Cyan
    New-AzVM -ResourceGroupName $VMNameRG -Location $Location -VM $VMConfig -Verbose -DisableBginfoExtension

    #Domain join VM with Azure exstension
    $Domaininfo = '{
    "Name": "domain.local",
    "User": "domain.local\\svc_joindomain",
    "OUPath": "OU=WVD,DC=Domain,DC=local",
    "Restart": "true",
    "Options": "3"
        }'
    $Secret = '{ "Password": "PasswordToServiceAccount" }'

    Write-Host "Installing VM Exstension Joindomain, and join $VMName to local domain" -ForegroundColor Cyan
    Set-AzVMExtension -VMName $VMName -ResourceGroupName $VMNameRG -Name "joindomain" -ExtensionType "JsonADDomainExtension" `
        -Publisher "Microsoft.Compute" -TypeHandlerVersion "1.0" -Location $Location `
        -SettingString $Domaininfo -ProtectedSettingString $Secret


    #Install DSC Exstension on Azure VM
    Write-Host "Install VM Exstension DSC" -ForegroundColor Cyan
    Set-AzVMExtension -VMName $VMName -ResourceGroupName $VMNameRG -Name "dscextension" -ExtensionType "DSC" `
        -Publisher "Microsoft.Powershell" -TypeHandlerVersion 2.26 -location $location 

    #Install Custom Script Exstension
    $protectedSettings = @{"commandToExecute" = "powershell -ExecutionPolicy Bypass -Force -File C:\Agents\DeployAgents.ps1" };

    Write-Host "Installing VM exstension CustomScriptExstension, and running DeployAgents.ps1 on $VMName" -ForegroundColor Cyan
    Set-AzVMExtension -ResourceGroupName $VMNameRG -Location $Location -VMName $VMName `
        -Name "serverUpdate" -Publisher "Microsoft.Compute" `
        -ExtensionType "CustomScriptExtension" `
        -TypeHandlerVersion "1.10" `
        
        -ProtectedSettings $protectedSettings


}
    ##*===============================================
    ##* END - SCRIPT BODY
    ##*===============================================