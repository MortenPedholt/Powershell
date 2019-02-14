#Connect-AzureRmAccount


#########################
# Edit These Variables! #
#########################
$scriptfolder = "C:\Github\Powershell\EMS\Intune"
$directoryname = "ITR.onmicrosoft.com"
$rgname = "ITR-IntuneService"
$location = "West Europe"
$automationaccountname = "ITR-Automationaccount"
$automationcredential = "IntuneAutomation"
$runbookName01 = "ITR_IntuneService"
$runbookName02 = "ITR"
$schedulename01 = "Daily Schedule for $($runbookName01)"
$schedulename02 = "Daily Schedule for $($runbookName02)"
$startTime = Get-date "13:00:00"


##########################
# THE SCRIPT STARTS HERE #
##########################

#Create resourcegroup
New-AzureRmResourceGroup -Name $rgname -Location $location

#Create Automation Account
New-AzureRmAutomationAccount -ResourceGroupName $rgname -Name $automationaccountname -Location $location

#Create Automation Variable
New-AzureRmAutomationVariable -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "DirectoryName" -Value $directoryname -Encrypted $false
New-AzureRmAutomationVariable -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "AppClientID" -Value "Valuetest" -Encrypted $false

#Create Automation Credential
New-AzureRmAutomationCredential -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name $automationcredential

#Create Automation Variables
New-AzureRmAutomationModule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "PSIntuneAuth" -ContentLinkUri "https://www.powershellgallery.com/packages/PSIntuneAuth/1.1.0"
New-AzureRmAutomationModule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name "AzureAD" -ContentLinkUri "https://www.powershellgallery.com/packages/AzureAD/2.0.2.4"

#IMport Automation Runbook for Apple Certificate and Schedule it
Import-AzureRmAutomationRunbook -Path "$scriptfolder\Get-appleMDMExpiration.ps1" -Name $runbookName01 -Type "PowerShell" -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
Publish-AzureRmAutomationRunbook -Name $runbookName01 -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
New-AzureRmAutomationSchedule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name $schedulename01 -StartTime $startTime -DayInterval 1
Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -RunbookName $runbookName01 -ScheduleName $schedulename01

#IMport Automation Runbook for VPP Certificate and Schedule it
Import-AzureRmAutomationRunbook -Path "$scriptfolder\Get-AppleVPPExpiration.ps1" -Name $runbookName02 -Type "PowerShell" -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
Publish-AzureRmAutomationRunbook -Name $runbookName02 -AutomationAccountName $automationaccountname  -ResourceGroupName $rgname
New-AzureRmAutomationSchedule -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -Name $schedulename02 -StartTime $startTime -DayInterval 1
Register-AzureRmAutomationScheduledRunbook -ResourceGroupName $rgname -AutomationAccountName $automationaccountname -RunbookName $runbookName02 -ScheduleName $schedulename02


$applicationname = "IntuneGraphAPI02"


$nativeapp = New-AzureADApplication -DisplayName $applicationname -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" -PublicClient $true 
set-AzureADApplication -Oauth2Permissions 'System.Collections.Generic.List`1[Microsoft.Open.AzureAD.Model.OAuth2Permission]'


$applicationid = $nativeapp.ApplicationId
