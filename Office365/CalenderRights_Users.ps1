# Created password file with this command.
#Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File C:\Scripts\o365Password_Scheduler.txt

# Finds the path for this script
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptPath = Split-Path $ScriptPath

# Connect and create Session
$password = type $ScriptPath\o365Password_Scheduler.txt | ConvertTo-SecureString 
$userid = "admin@domain.com"
$cred = New-Object System.Management.Automation.PSCredential $userid,$password 
$global:session365 = New-PSSession -configurationname Microsoft.Exchange -connectionuri https://outlook.office365.com/powershell-liveid/ -credential $cred -authentication Basic -AllowRedirection 
Import-PSSession $global:session365
Connect-MsolService -Credential $cred
$mailgroup = mailgroup@domain.com


#$Mailboxes = Get-Mailbox -Filter '(RecipientTypeDetails -eq "UserMailbox")'
$Mailboxes = Get-DistributionGroupMember -Identity danpocalendarsharing@Scandistandard.com | Get-Mailbox
$Mailboxes | ForEach-Object {
    	
    $CalendarPath = $_.UserPrincipalName + ":\" + (Get-MailboxFolderStatistics $_.Identity | Where-Object { $_.Foldertype -eq "Calendar" } | Select-Object -First 1).Name
 
Write-Host $CalendarPath  
#Add folderpermisson on group
Add-MailboxFolderPermission $CalendarPath -User $mailgroup -AccessRights LimitedDetails

#change folderpermisson on group
Set-MailboxFolderPermission $CalendarPath -User $mailgroup -AccessRights LimitedDetails

}

# Disconnects the Session
Get-PSSession | Remove-PSSession