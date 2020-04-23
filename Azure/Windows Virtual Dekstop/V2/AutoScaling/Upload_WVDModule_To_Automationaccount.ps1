#Create new storageaccount and upload powershel modules
$scriptpath = Get-Location
$rgname = ""
$storageaccountname = ""
$blobname = ""
$location = "West Europe"
$AutomationAccountName = ""
New-AzStorageAccount -ResourceGroupName $rgname -Location $location -Name $storageaccountname -SkuName "Standard_LRS"
Set-AzCurrentStorageAccount -AccountName $storageaccountname -ResourceGroupName $rgname
New-AzStorageContainer -Name $blobname -Permission "Blob"
Set-AzstorageBlobContent -File "$($scriptpath)\Az.DesktopVirtualization.0.0.6.nupkg" -Container $blobname


New-AzAutomationModule -ResourceGroupName $rgname -AutomationAccountName $AutomationAccountName -Name "Az.DesktopVirtualization" -ContentLinkUri "https://$($storageaccountname).blob.core.windows.net/$blobname/Az.DesktopVirtualization.0.0.6.nupkg"
