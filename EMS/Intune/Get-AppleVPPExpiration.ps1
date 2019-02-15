function Send-O365MailMessage {
    param (
        [parameter(Mandatory=$true)]
        [string]$Credential,
        [parameter(Mandatory=$false)]  
        [string]$Body,
        [parameter(Mandatory=$false)]  
        [string]$Subject,
        [parameter(Mandatory=$true)]  
        [string]$Recipient,
        [parameter(Mandatory=$true)]  
        [string]$From
    )
    # Get Azure Automation credential for authentication  
    $PSCredential = Get-AutomationPSCredential -Name $Credential

    # Construct the MailMessage object
    $MailMessage = New-Object -TypeName System.Net.Mail.MailMessage  
    $MailMessage.From = $From
    $MailMessage.ReplyTo = $From
    $MailMessage.To.Add($Recipient)
    $MailMessage.Body = $Body
    $MailMessage.BodyEncoding = ([System.Text.Encoding]::UTF8)
    $MailMessage.IsBodyHtml = $true
    $MailMessage.SubjectEncoding = ([System.Text.Encoding]::UTF8)

    # Attempt to set the subject
    try {
        $MailMessage.Subject = $Subject
    } 
    catch [System.Management.Automation.SetValueInvocationException] {
        Write-Warning -InputObject "An exception occurred while setting the message subject"
    }

    # Construct SMTP Client object
    $SMTPClient = New-Object -TypeName System.Net.Mail.SmtpClient -ArgumentList @("smtp.office365.com", 587)
    $SMTPClient.Credentials = $PSCredential 
    $SMTPClient.EnableSsl = $true 

    # Send mail message
    $SMTPClient.Send($MailMessage)
}

# Import required modules
try {
    Import-Module -Name AzureAD -ErrorAction Stop
    Import-Module -Name PSIntuneAuth -ErrorAction Stop
}
catch {
    Write-Warning -Message "Failed to import modules"
}
# Read credentials and variables
$Credential = Get-AutomationPSCredential -Name "IntuneAutomation"
$AppClientID = Get-AutomationVariable -Name "AppClientID"
$TenantName = Get-AutomationVariable -Name "DirectoryName"

# Acquire authentication token
try {
    Write-Output -InputObject "Attempting to retrieve authentication token"
    $AuthToken = Get-MSIntuneAuthToken -TenantName $TenantName -ClientID $AppClientID -Credential $Credential
    if ($AuthToken -ne $null) {
        Write-Output -InputObject "Successfully retrieved authentication token"
    }
}
catch [System.Exception] {
    Write-Warning -Message "Failed to retrieve authentication token"
}
# Get Apple VPP tokens
Write-Output -InputObject "Attempting to retrieve Apple VPP tokens"
$AppleVPPResource = "https://graph.microsoft.com/beta/deviceAppManagement/vppTokens"
$AppleVPPTokens = (Invoke-RestMethod -Uri $AppleVPPResource -Method Get -Headers $AuthToken).Value
# Validate tokens
if ($AppleVPPTokens -ne $null) {
    foreach ($AppleVPPToken in $AppleVPPTokens) {
        $AppleVPPExpirationDate = [System.DateTime]::Parse($AppleVPPToken.expirationDateTime)
        if ($AppleVPPExpirationDate -lt (Get-Date)) {
            Write-Output -InputObject "Apple VPP token has already expired"
        }
        else {
            $AppleVPPTokenDaysLeft = ($AppleVPPExpirationDate-(Get-Date))
            Write-Output -InputObject "Apple VPP token expires in days: $($AppleVPPTokenDaysLeft.Days)"
        }
    }
}
else {
    Write-Output -InputObject "Query for Apple VPP tokens returned empty"
}