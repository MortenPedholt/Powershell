## NOTE
# Hvis ikke man har sat settings før, så tag en a dgangen
# for, at kunne reverte til tidligere, så systemer ikke
# påvirkes.
#
#
##

#Import ExchangeOnline 
# // hent Exo modulet fra admin.microsoft.com -> Exchange -> Hybrid
Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$EXOSession = New-ExoPSSession
Import-PSSession $EXOSession

#Install Orca
Install-Module ORCA

#Run ORCA
Get-ORCAReport

#Hent ExchangeObjectID pr Set
$HostedContentFilterPolicyID = (Get-HostedContentFilterPolicy).ExchangeObjectID
$HostedOutboundSpamFilterPolicyID = (Get-HostedOutboundSpamFilterPolicy).ExchangeObjectID
$MalwareFilterPolicyID = (Get-MalwareFilterPolicy).ExchangeObjectID
$AntiPhishPolicyID = (Get-AntiPhishPolicy).ExchangeObjectId



#  Ændret fra 7 til 6
Set-HostedContentFilterPolicy -Identity $HostedContentFilterPolicyID.Guid -BulkThreshold 6 

# Sæt RecipientLimitExternalPerHour (https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/recommended-settings-for-eop-and-office365-atp#anti-spam-anti-malware-and-anti-phishing-protection-in-eop)
Set-HostedOutboundSpamFilterPolicy -Identity $HostedOutboundSpamFilterPolicyID.Guid -RecipientLimitExternalPerHour 500

# Sæt RecipientLimitInternalPerHour 
Set-HostedOutboundSpamFilterPolicy -Identity $HostedOutboundSpamFilterPolicyID.Guid -RecipientLimitInternalPerHour 1000

# Sæt RecipientLimitPerDay 
Set-HostedOutboundSpamFilterPolicy -Identity $HostedOutboundSpamFilterPolicyID.Guid -RecipientLimitPerDay 1000

# Sæt ActionWhenThresholdReached
Set-HostedOutboundSpamFilterPolicy -Identity $HostedOutboundSpamFilterPolicyID.Guid -ActionWhenThresholdReached BlockUser


# Sæt Confidence SPAM til Quarantine (fra MoveToJmF)
Set-HostedContentFilterPolicy -Identity $HostedContentFilterPolicyID.Guid -HighConfidenceSpamAction Quarantine

# Sæt BulkSpamAction til MoveToJMF (to Quarantine)
Set-HostedContentFilterPolicy -Identity $HostedContentFilterPolicyID.Guid -BulkSpamAction MovetoJMF

# Sæt Phish Action to Quarantine message (from MoveToJmF)
Set-HostedContentFilterPolicy -Identity $HostedContentFilterPolicyID.Guid -PhishSpamAction Quarantine

#Sæt DKIM op :-)
#sjov ting ifbm MFA -)
Get-Command -Module tmp_dmwhjqj3.m1c *dkim*
# New-DkimSigningConfig -DomainName win74ever.dk -Enabled $true
Set-DkimSigningConfig -Identity win74ever.dk -Enabled $true

# Unified Audit Log (Security & Compliance Center, go to Search > Audit log search)
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# Enable File filter * OBS Identity er anderledes fra "HostedContentFilterPolicy" 
Set-MalwareFilterPolicy -Identity $MalwareFilterPolicyID.Guid -EnableFileFilter $true

# Enable Safe Links (O365 ATP)
Set-AtpPolicyForO365 -TrackClicks $true

# Enable EnableATPForSPOTeamsODB
Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true

# Enable EnableSafeLinksForClients
Set-AtpPolicyForO365 -EnableSafeLinksForClients $true

# Enable Intra-organization Safe Links
## Laves via GUI for nu :( (https://protection.office.com)

# Hæv Anti-Phising ThresholdLevel til 2 (standard 1, 2 aggresiv, 3 meget aggresiv)
Set-AntiPhishPolicy -Identity $AntiPhishPolicyID.Guid -PhishThresholdLevel 2

# AntiphishPolicy TargetedDomainsToProtect
Set-AntiPhishPolicy -Identity $AntiPhishPolicyID.Guid -EnableTargetedDomainsProtection $false

# AntiphishPolicy EnableOrganizationDomainsProtection
Set-AntiPhishPolicy -Identity $AntiPhishPolicyID.Guid -EnableOrganizationDomainsProtection $true

# AntiPhishPolicy TargetedDomainProtectionAction 
Set-AntiPhishPolicy -Identity $AntiPhishPolicyID.Guid -TargetedDomainProtectionAction Quarantine -TargetedDomainActionRecipients tba@win74ever.dk

# AntiphishPolicy TargetedUserProtectionAction // Enable
Set-AntiPhishPolicy -Identity $AntiPhishPolicyID.Guid -TargetedUserProtectionAction Quarantine -EnableTargetedUserProtection $true -TargetedUserActionRecipients tba@win74ever.dk

# EnableSimilarUsersSafetyTips
Set-AntiPhishPolicy -Identity $AntiPhishPolicyID.Guid -EnableSimilarUsersSafetyTips $true
