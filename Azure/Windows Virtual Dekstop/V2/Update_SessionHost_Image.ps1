##*===============================================
##* START - PARAMETERS
##*===============================================
$ImageName = ""

$NamePrefix = ""

$DomainName = ""
$HostpoolName = ""
$HostpoolNameRG = ""

$Cred = (Get-Credential)

##*===============================================
##* END - PARAMETERS
##*===============================================

##*===============================================
##* START - SCRIPT BODY
##*===============================================



#Get VM Prefixes
$Date = (get-date -f dd-MM-yyyy)

$CurrentWVDVMS = Get-AzVM | Where-Object { $_.Name -like "$($NamePrefix)-*" } -ErrorAction SilentlyContinue
write-host "There is $($currentWVDVMS.count) VMS that will be updated" -ForegroundColor Cyan
write-host "Waiting one minute before continue, after the minut is done all VMS named $NamePrefix will be recreated.." -ForegroundColor Cyan

foreach ($CurrentWVDVM in $CurrentWVDVMS.Name){
    $CurrentVM = Get-AzVM | Where-Object { $_.Name -eq $CurrentWVDVM }
 $CurrentVMName = $CurrentVM.Name
    
    $CurrentVM.FullyQualifiedDomainName

    Write-Host "Getting VM information for $CurrentVMName..." -ForegroundColor Cyan
   
    #Check Network
    Write-Host "Getting Network information for $CurrentVMName .." -ForegroundColor Cyan
    $CurrentVMNetworkSettings = $CurrentVM.NetworkProfile.NetworkInterfaces[0].Id | Get-AzNetworkInterface
    
    #Check Availability set
    Write-Host "Getting avilabilityset for WVD Hostpool.." -ForegroundColor Cyan
    $CurrentAvailabilitySet = $CurrentVM.AvailabilitySetReference
   
    #Get Disk
    Write-Host "Getting Disk information for $CurrentVMName.." -ForegroundColor Cyan
    $CurrentOSDiskConfig = $CurrentVM.StorageProfile.OsDisk
    
    #Get Custom Image
    Write-Host "Getting information about custom image.." -ForegroundColor Cyan
    $imageversion = Get-AzImage | Where-Object { $_.Name -eq $ImageName }

    #Prepare VM config
    Write-Host "Setting new VM configuration.." -ForegroundColor Cyan

    $VMConfig = New-AzVMConfig -VMName $CurrentVMName -VMSize $CurrentVM.HardwareProfile.VmSize -AvailabilitySetId $CurrentAvailabilitySet -LicenseType $CurrentVM.LicenseType
    $VMConfig = Set-AzVMOperatingSystem -VM $VMConfig -Windows -ComputerName $CurrentVM.OSProfile.ComputerName -Credential $Cred
    $VMConfig = Set-AZVMBootDiagnostic -VM $VMConfig -Disable
    $VMConfig = Set-AzVMSourceImage -VM $VMConfig -Id $imageversion.id
    $VMConfig = Add-AzVMNetworkInterface -VM $VMConfig -Id $CurrentVMNetworkSettings.Id
    $VMConfig = Set-AzVMOSDisk -VM $VMConfig -Name "$($CurrentOSDiskConfig.Name)-Updated-$Date" -DiskSizeInGB $CurrentOSDiskConfig.DiskSizeGB -StorageAccountType $CurrentOSDiskConfig.ManagedDisk.StorageAccountType -CreateOption "Fromimage"
    
    

    #Remove from WVD Hostpool
    Write-Host "Checking WVD Sessionhost for usersession" -ForegroundColor Cyan
    $SessionHostName = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -Name "$CurrentVMName.$DomainName" -ErrorAction SilentlyContinue
    if ($SessionHostName) {
        $SessionHostName = $SessionHostName.Name.Split("/")
        $SessionHostName = $SessionHostName[1]
        $checkusersessions = Get-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -SessionHostName $SessionHostName
        if ($checkusersessions) {
            Write-Host "User is logged on $SessionHostName, sending message to user, they will be logged off in 2 minutes" -ForegroundColor Cyan
               
            foreach ($checkusersession in $checkusersessions) {

                $SessionID = $checkusersession.Name.Split("/")
                $SessionID = $SessionID[2]
                Send-AzWvdUserSessionMessage -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -SessionHostName $SessionHostName -UserSessionId $SessionID -MessageTitle "IMPORTANT MAINTENANCE" -MessageBody "You will be logged off in 2 minutes, make sure to save your work!"
                write-host "Message has been sent to user session ID $SessionID on Sessionhost $SessionHostName" -ForegroundColor Cyan
            }
            Start-Sleep 120
        
            foreach ($checkusersession in $checkusersessions) {

                $SessionID = $checkusersession.Name.Split("/")
                $SessionID = $SessionID[2]
                Disconnect-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -SessionHostName $SessionHostName -UserSessionId $SessionID
            
            }

            Write-Host "Removeing $SessionHostName from WVD Pool " -ForegroundColor Cyan
            Remove-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -Name $SessionHostName -Force




        }
        else {
       
            Write-Host "There is no user logged on to $SessionHostName" -ForegroundColor Cyan
            Write-Host "Removeing $SessionHostName from WVD Pool " -ForegroundColor Cyan
            Remove-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -Name $SessionHostName -Force

        }
    }
    else {

        write-host "$CurrentVMName is not registred for WVD" -ForegroundColor Cyan
    }


    Write-Host "Removeing $SessionHostName from WVD Pool " -ForegroundColor Cyan
    Remove-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostpoolNameRG -Name $SessionHostName -Force

    
    #Remove old VM and disk
    Write-Host "Removeing old VM..." -ForegroundColor Cyan
    Remove-AzVM -Name $CurrentVMName -ResourceGroupName $CurrentVM.ResourceGroupName -Force -verbose
    Remove-AzDisk -DiskName $CurrentOSDiskConfig.name -ResourceGroupName $CurrentVM.ResourceGroupName -Force -verbose


    #Create new VM
    Write-Host "Creating VM with new Image.." -ForegroundColor Cyan
    $VMConfig = New-AzVMConfig -VMName $CurrentVMName -VMSize $CurrentVM.HardwareProfile.VmSize -AvailabilitySetId $CurrentAvailabilitySet.id -LicenseType $CurrentVM.LicenseType
    $VMConfig = Set-AzVMOperatingSystem -VM $VMConfig -Windows -ComputerName $CurrentVM.OSProfile.ComputerName -Credential $Cred
    $VMConfig = Set-AZVMBootDiagnostic -VM $VMConfig -Disable
    $VMConfig = Set-AzVMSourceImage -VM $VMConfig -Id $imageversion.id
    $VMConfig = Add-AzVMNetworkInterface -VM $VMConfig -Id $CurrentVMNetworkSettings.Id
    $VMConfig = Set-AzVMOSDisk -VM $VMConfig -Name "$($CurrentVMName)-osdisk-Updated-$Date" -DiskSizeInGB $CurrentOSDiskConfig.DiskSizeGB -StorageAccountType $CurrentOSDiskConfig.ManagedDisk.StorageAccountType -CreateOption "Fromimage"
       

    New-AzVM -ResourceGroupName $CurrentVM.ResourceGroupName -Location $CurrentVM.Location -VM $VMConfig -Verbose -DisableBginfoExtension

    #Domain join VM with Azure exstension
    $Domaininfo = '{
    "Name": "domain.local",
    "User": "domain.local\\svc_joindomain",
    "OUPath": "OU=WVD,DC=Domain,DC=local",
    "Restart": "true",
    "Options": "3"
        }'
    $Secret = '{ "Password": "PasswordToStorageAccount" }'

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

