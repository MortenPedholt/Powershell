Connect-AzAccount
$subscriptions = Get-AzSubscription
$exportpath = "C:\Temp\azuretags.csv"
ForEach ($vsub in $subscriptions){
Select-Object $vsub.SubscriptionID

Write-Host “Working on subscription“ $vsub.Name "With subscription ID" "($vsub)" -ForegroundColor Green

$result=@()
$tagkeys=Get-AzTag
foreach($tagkey in $tagkeys) {
	$tagvalues=(Get-AzTag $tagkey.name).values
	foreach($tagvalue in $tagvalues) {
		$result+=get-AzResource -tag @{$tagkey.name=$tagvalue.name} | Select-Object ResourceName,Resourcetype,Resourcegroupname,Location,@{label="tagName";expression={$tagkey.name}},@{label="tagValue";expression={$tagvalue.name}},ResourceId
	}
}
$result | export-csv $exportpath -Append
#$result | Out-GridView -Title "Azure Resources that have been assigned with tags"


$result=@()
$tagkeys=Get-AzTag
foreach($tagkey in $tagkeys) {
	$tagvalues=(Get-AzTag $tagkey.name).values
	foreach($tagvalue in $tagvalues) {
		$result+=Get-AzResourceGroup -tag @{$tagkey.name=$tagvalue.name} | Select-Object ResourceName,Resourcetype,Resourcegroupname,Location,@{label="tagName";expression={$tagkey.name}},@{label="tagValue";expression={$tagvalue.name}},ResourceId
	}
}
$result | export-csv $exportpath -Append

}

#>

####
#Get resources with tag and output in grid
####
<#

$result=@()
$tagkeys=Get-AzTag
foreach($tagkey in $tagkeys) {
	$tagvalues=(Get-AzTag $tagkey.name).values
	foreach($tagvalue in $tagvalues) {
		$result+=Find-AzResource -tag @{$tagkey.name=$tagvalue.name} | Select-Object name,resourcetype,SubscriptionId,resourcegroupname,location,@{label="tagName";expression={$tagkey.name}},@{label="tagValue";expression={$tagvalue.name}}
	}
}
$result | Out-GridView -Title "Azure Resources that have been assigned with tags"
#>