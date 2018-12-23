# Created password file with this command.
# Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File C:\Scripts\o365Password_Scheduler.txt

# Finds the path for this script

$ScriptPath = get-location

# Connect and create Session
$password = type $ScriptPath\o365Password_Scheduler.txt | ConvertTo-SecureString 
$userid = "adminaccount@domain.com"
$cred = New-Object System.Management.Automation.PSCredential $userid,$password 
$global:session365 = New-PSSession -configurationname Microsoft.Exchange -connectionuri https://outlook.office365.com/powershell-liveid/ -credential $cred -authentication Basic -AllowRedirection 
Import-PSSession $global:session365
Connect-MsolService -Credential $cred

#----------------------#
    #change this!#
#----------------------#
$mailgroup = "mailgroup@domain.com"
$accessrights = "LimitedDetails"


#add usermailbox to group
$usermailboxes = Get-Mailbox -Filter '(RecipientTypeDetails -eq "UserMailbox")' | select DistinguishedName
$usermailboxes | ForEach {Add-DistributionGroupMember -Identity $mailgroup -Member $_.DistinguishedName}

#Change calendar rights
 $mailboxes = Get-DistributionGroupMember -Identity $mailgroup | Get-Mailbox
 $mailboxes | ForEach-Object {
    	
    $calendarpath = $_.UserPrincipalName + ":\" + (Get-MailboxFolderStatistics $_.Identity | Where-Object { $_.Foldertype -eq "Calendar" } | Select-Object -First 1).Name
 
#add rights on group  
# Tilføjer gruppen hvis den ikke er der
Add-MailboxFolderPermission $calendarpath -User $mailgroup -AccessRights $accessrights


#change rights on group
Set-MailboxFolderPermission $calendarpath -User $mailgroup -AccessRights $accessrights

}

#Add Rooms to group
$RessourceMailboxes = get-mailbox -Filter '(RecipientTypeDetails -eq "RoomMailbox")' | select DistinguishedName
$RessourceMailboxes | ForEach {Add-DistributionGroupMember -Identity $mailgroup -Member $_.DistinguishedName}

#Change Calendar rights
$RessourceMailboxes = get-mailbox   | where {$_.recipientTypeDetails -eq "roomMailbox"}
$RessourceMailboxes | ForEach-Object {

    $CalendarPath = $_.UserPrincipalName + ":\" + (Get-MailboxFolderStatistics $_.Identity | Where-Object { $_.Foldertype -eq "Calendar" } | Select-Object -First 1).Name
 
Write-Host $CalendarPath  
#add rights on group
Add-MailboxFolderPermission $CalendarPath -User $mailgroup -AccessRights $accessrights

#change rights on group
Set-MailboxFolderPermission $CalendarPath -User $mailgroup -AccessRights $accessrights

}

 #Disconnects the Session
Get-PSSession | Remove-PSSession