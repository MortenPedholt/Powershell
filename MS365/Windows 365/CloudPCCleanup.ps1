$dt = (Get-Date).AddDays(-30)

$staledevices = Get-AzureADDevice -All:$true | Where {$_.DisplayName -like "*CPC-*" -and $_.ApproximateLastLogonTimeStamp -le $dt} #-and $_.AccountEnabled -eq $False } | select-object -Property AccountEnabled, ObjectId, DeviceId, DeviceOSType, DeviceOSVersion, DisplayName, DeviceTrustType, ApproximateLastLogonTimestamp

Write-Verbose "There is $($staledevices.count) AccountDisabled Cloud PC devices that haven't been online after $dt" -Verbose

foreach ($device in $staledevices){

 $DeviceOwner = Get-AzureADDeviceRegisteredOwner -ObjectId $device.ObjectId
    if ($DeviceOwner){
    Write-Verbose "Owner of Device: $($Device.DisplayName) is: $($DeviceOwner.UserPrincipalName)" -Verbose

    Write-Verbose "Getting all Cloud PC devices for user: $($DeviceOwner.UserPrincipalName)" -Verbose
    $UserCloudPC = Get-AzureADUserOwnedDevice -ObjectId $DeviceOwner.ObjectId | Where {$_.DisplayName -like "*CPC-*"}
 
    Write-Verbose "User $($DeviceOwner.UserPrincipalName) has $($UserCloudPC.Count) CloudPC" -Verbose
    $DisabledCloudPC = Get-AzureADUserOwnedDevice -ObjectId $DeviceOwner.ObjectId | Where {$_.DisplayName -like "*CPC-*" -and $_.ApproximateLastLogonTimeStamp -le $dt -and $_.AccountEnabled -eq $False} 
    Write-Verbose "$($DisabledCloudPC.Count) out of $($UserCloudPC.Count) CloudPC is disabled and is no longer in use" -Verbose
    
    
        Write-Verbose "Removeing Device $($Device.DisplayName)" -Verbose
        #Remove-AzureADDevice -ObjectId $device.ObjectId
    } else{
       
       Write-Verbose "Unable to find device owner for CloudPC: $($Device.DisplayName) Skipping this PC" -Verbose


    }



}










#$test = Get-AzureADDevice -All:$true | Where {$_.DisplayName -like "CPC-mp-H2L0Z-95"}














foreach ($device in $staledevices){

Write-output "Removeing Workplacejoined device '$($device.DisplayName)'"
Write-output "last check-in date was $($device.ApproximateLastLogonTimeStamp)"
Write-output "DeviceOSType is $($device.DeviceOSType)"
Write-output "ObjectID is $($device.ObjectId)"
Remove-AzureADDevice -ObjectId $device.ObjectId

}

Get-AzureADDevice -All:$true | Where {$_.DisplayName -eq "CPC-mp-W909M-GY" -and $_.AccountEnabled -eq "False" }