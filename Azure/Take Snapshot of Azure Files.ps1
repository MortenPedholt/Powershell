
$context = New-AzStorageContext -StorageAccountName "accountname" -StorageAccountKey "Storagekey"

$share = Get-AzStorageShare -Context $context -Name "sharename"

$snapshot = $share.Snapshot()