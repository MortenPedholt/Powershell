#Modules Required
#Requires -modules Az.Resources, Az.Accounts

#Parameters

$ExpiresInDays = 90 #HelpMessage = Will output credentials if withing this number of days, use 0 to report only expired and valid as of today
$MailTo = ""
$MailFrom = ""
$MailCredentials = Get-Credential #Needs to have an Exchange online mailbox til be able to send the email



#Connect to Azure
Connect-AzAccount

Write-Verbose 'Gathering necessary information about Servince Principals...' -Verbose
$applications = Get-AzADApplication
$servicePrincipals = Get-AzADServicePrincipal

$appWithCredentials = @()
$appWithCredentials += $applications | Sort-Object -Property DisplayName | ForEach-Object {
 $application = $_
 $sp = $servicePrincipals | Where-Object ApplicationId -eq $application.ApplicationId
 Write-Verbose ('Fetching information for application {0}' -f $application.DisplayName)
 $application | Get-AzADAppCredential -ErrorAction SilentlyContinue | Select-Object -Property @{Name='DisplayName'; Expression={$application.DisplayName}}, @{Name='ObjectId'; Expression={$application.Id}}, @{Name='ApplicationId'; Expression={$application.ApplicationId}}, @{Name='KeyId'; Expression={$_.KeyId}}, @{Name='Type'; Expression={$_.Type}},@{Name='StartDate'; Expression={$_.StartDate -as [datetime]}},@{Name='EndDate'; Expression={$_.EndDate -as [datetime]}}
}

Write-Verbose 'Validating expiration dates...' -Verbose
$today = (Get-Date).ToUniversalTime()
$limitDate = $today.AddDays($ExpiresInDays)
$appWithCredentials | Sort-Object EndDate | ForEach-Object {
     if($_.EndDate -lt $today) {
         $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Expired'
     } elseif ($_.EndDate -le $limitDate) {
         $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'ExpiringSoon'
     } else {
         $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Valid'
     }
}

Write-Verbose "Done getting information about Service Principals" -Verbose

$MailBody = $appWithCredentials | Where-Object {$_.Status -ne "Valid"} |  Out-String

$MailBody

Write-Verbose "Sending email to $MailTo" -Verbose
Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Subject "ATTENTION: the following Service Principals in AzureAD is expired or is going to expire within $ExpiresInDays Days!" -Body $MailBody -Credential $MailCredentials -UseSsl                           