#Install-module -Name AzureAD
#Connect-AzureAD
Get-AzureADUser| Select-Object UserprincipalName,ImmutableID,WhenCreated,LastDirSyncTime

$user = Get-ADUser -Identity ""
$guid = [guid](($user)).objectGuid
$immutableId = [System.Convert]::ToBase64String($guid.ToByteArray())



#Object ID på Cloud-only bruger
$objectID = ""

Set-AzureADUser -ObjectId $objectID -ImmutableId $immutableID