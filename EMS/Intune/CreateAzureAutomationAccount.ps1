Connect-AzureRmAccount


#########################
# Edit These Variables! #
#########################
$directoryname = "Directoryname"
$applicationid = "aaaaaaa-aaaa-bbbb-cccc-dddddd"

#####################
# No need to change #
#####################
$scriptpath = Get-Location
$rgname = "ITR-IntuneService"
$location = "West Europe"
$automationaccountname = "ITR-Automationaccount"
$automationcredential = "IntuneAutomation"
$runbookName01 = "ITR_Apple_Cert"
$runbookName02 = "ITR_VPP_Cert"
$schedulename01 = "Daily Schedule for $($runbookName01)"
$schedulename02 = "Daily Schedule for $($runbookName02)"
$startTime = (get-date).AddDays(+1)
$storageaccountname = "itrintuneserviceformdm"
$blobname = "powershellmodulesformdm"


##########################
# THE SCRIPT STARTS HERE #
##########################

#Create resourcegroup
New-AzureRmResourceGroup -Name $rgname -Location $location

#Create new storageaccount and upload powershel modules
New-AzureRmStorageAccount -ResourceGroupName $rgname -Location $location -Name $storageaccountname -SkuName "Standard_LRS"
New-AzureRmStorageContainer -Name $blobname -ResourceGroupName $rgname -StorageAccountName $storageaccountname -PublicAccess "Blob"
Set-AzureRmCurrentStorageAccount -AccountName $storageaccountname -ResourceGroupName $rgname
Set-AzureStorageBlobContent -File "$($scriptpath)\psintuneauth.1.1.0.nupkg" -Container $blobname
Set-AzureStorageBlobContent -File "$($scriptpath)\azuread.2.0.2.4.nupkg" -Container $blobname


#Create Automation Account
New-AzureRmAutomationAccount -ResourceGroupName $rgname -Name $automationaccountname -Location $location

#Create Automation Variable
New-AzureRmAutomationVariable -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "DirectoryName" -Value $directoryname -Encrypted $false
New-AzureRmAutomationVariable -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "AppClientID" -Value $applicationid -Encrypted $false

#Create Automation Credential
New-AzureRmAutomationCredential -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name $automationcredential

#Create Automation Variables
New-AzureRmAutomationModule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "PSIntuneAuth" -ContentLinkUri "https://$($storageaccountname).blob.core.windows.net/$blobname/psintuneauth.1.1.0.nupkg"
New-AzureRmAutomationModule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "AzureAD" -ContentLinkUri "https://$($storageaccountname).blob.core.windows.net/$blobname/azuread.2.0.2.4.nupkg"

#Import  Runbook for Apple Certificate and Schedule it
Import-AzureRmAutomationRunbook -Path "$scriptpath\Get-appleMDMExpiration.ps1" -Name $runbookName01 -Type "PowerShell" -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
Publish-AzureRmAutomationRunbook -Name $runbookName01 -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
New-AzureRmAutomationSchedule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name $schedulename01 -StartTime $startTime -DayInterval 1
Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -RunbookName $runbookName01 -ScheduleName $schedulename01

#Import  Runbook for VPP Certificate and Schedule it
Import-AzureRmAutomationRunbook -Path "$scriptpath\Get-AppleVPPExpiration.ps1" -Name $runbookName02 -Type "PowerShell" -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
Publish-AzureRmAutomationRunbook -Name $runbookName02 -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
New-AzureRmAutomationSchedule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name $schedulename02 -StartTime $startTime -DayInterval 1
Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -RunbookName $runbookName02 -ScheduleName $schedulename02

#Delete Storage account
Remove-AzureRmStorageAccount -ResourceGroupName $rgname -AccountName $storageaccountname -Force