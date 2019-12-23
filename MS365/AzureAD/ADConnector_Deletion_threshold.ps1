#See how many users, groups and devices there is in scope of AzureAD connect

$c = Get-ADSyncConnector –Name domain.tld
$ous = ($c).Partitions.ConnectorPartitionScope.ContainerInclusionList

 

$ADUsers = @()
$ADGroups = @()
$ADComputers = @()

ForEach ($ou in $ous){
$ADUsers += (Get-ADUser -SearchBase $ou -Filter *)

}
ForEach ($ou in $ous){
$ADGroups += (Get-ADGroup -SearchBase $ou -Filter *)
}
ForEach ($ou in $ous){
$ADComputers += (Get-ADComputer -SearchBase $ou -Filter *)

}

Write-Host
Write-Host “Total number of users is” $ADUsers.count
Write-Host “Total number of groups is” $ADGroups.count
Write-Host “Total number of devices is” $ADComputers.count

#View Deletion threshold
Get-ADSyncExportDeletionThreshold

#Disable Deletion Threshold
#Disable-ADSyncExportDeletionThreshold

#Enable Deletion Threshold
Enable-ADSyncExportDeletionThreshold -DeletionThreshold 500

