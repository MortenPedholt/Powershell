#Connect-AzureRmAccount
$subscriptions = Get-AzSubscription
$exportpath = "C:\test01.csv"
ForEach ($vsub in $subscriptions){
Select-AzSubscription $vsub.SubscriptionID

Write-Host

Write-Host “Working on“ $vsub

$result=@()
$tagkeys=Get-AzTag
foreach($tagkey in $tagkeys) {
	$tagvalues=(Get-AzTag $tagkey.name).values
	foreach($tagvalue in $tagvalues) {
		$result+=Find-AzResource -tag @{$tagkey.name=$tagvalue.name} | select Name,Resourcetype,SubscriptionId,Resourcegroupname,Location,@{label="tagName";expression={$tagkey.name}},@{label="tagValue";expression={$tagvalue.name}}
	}
}
$result | export-csv $exportpath -Append

$result=@()
$tagkeys=Get-AzTag
foreach($tagkey in $tagkeys) {
	$tagvalues=(Get-AzTag $tagkey.name).values
	foreach($tagvalue in $tagvalues) {
		$result+=Find-AzResourceGroup -tag @{$tagkey.name=$tagvalue.name} | select Name,Resourcetype,SubscriptionId,Resourcegroupname,Location,@{label="tagName";expression={$tagkey.name}},@{label="tagValue";expression={$tagvalue.name}}
	}
}
$result | export-csv $exportpath -Append

}



####
#Get resources with tag and output in grid
####
<#

$result=@()
$tagkeys=Get-AzTag
foreach($tagkey in $tagkeys) {
	$tagvalues=(Get-AzTag $tagkey.name).values
	foreach($tagvalue in $tagvalues) {
		$result+=Find-AzResource -tag @{$tagkey.name=$tagvalue.name} | select name,resourcetype,SubscriptionId,resourcegroupname,location,@{label="tagName";expression={$tagkey.name}},@{label="tagValue";expression={$tagvalue.name}}
	}
}
$result | Out-GridView -Title "Azure Resources that have been assigned with tags"
#>