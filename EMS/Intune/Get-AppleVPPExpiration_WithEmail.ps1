# Functions
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

#########################
# Edit These Variables! #
#########################

$MailFrom = "exmoped@GeorgJensenGlobal.onmicrosoft.com"
$MailRecipient = "moped@itrelation.dk"
$AppleMDMPushCertificateNotificationRange = 250

##########################
# THE SCRIPT STARTS HERE #
##########################

# Email Sender Account
$AzureAutomationCredentialName = "IntuneAutomation"

# Azure Automation variables
$AzureAutomationCredentialName = "IntuneAutomation"
$AzureAutomationVariableAppClientID = "AppclientID"
$AzureAutomationVariableTenantName = "DirectoryName"


try {
    # Import required modules
    Write-Output -InputObject "Importing required modules AzureAD and PSIntuneAuth"
    Import-Module -Name AzureAD -ErrorAction Stop
    Import-Module -Name PSIntuneAuth -ErrorAction Stop

    try {
        # Read credentials and variables
        Write-Output -InputObject "Reading automation variables"
        $Credential = Get-AutomationPSCredential -Name $AzureAutomationCredentialName -ErrorAction Stop
        $AppClientID = Get-AutomationVariable -Name $AzureAutomationVariableAppClientID -ErrorAction Stop
        $TenantName = Get-AutomationVariable -Name $AzureAutomationVariableTenantName -ErrorAction Stop

        try {
            # Retrieve authentication token
            Write-Output -InputObject "Attempting to retrieve authentication token"
            $AuthToken = Get-MSIntuneAuthToken -TenantName $TenantName -ClientID $AppClientID -Credential $Credential -ErrorAction Stop
            if ($AuthToken -ne $null) {
                Write-Output -InputObject "Successfully retrieved VPP authentication token"

                try {
                    # Get Apple VPP Push certificates
                    $AppleVPPPushResource = "https://graph.microsoft.com/v1.0/devicemanagement/applePushNotificationCertificate"
                    $AppleVPPPushCertificate = Invoke-RestMethod -Uri $AppleVPPPushResource -Method Get -Headers $AuthToken -ErrorAction Stop

                    if ($AppleVPPPushCertificate -ne $null) {
                        Write-Output -InputObject "Successfully retrieved Apple VPP Push certificate"

                        # Parse the JSON date time string into an DateTime object
                        $AppleVPPPushCertificateExpirationDate = [System.DateTime]::Parse($AppleVPPPushCertificate.expirationDateTime)
                    
                        # Validate that the VPP Push certificate has not already expired
                        if ($AppleVPPPushCertificateExpirationDate -lt (Get-Date)) {
                            Write-Output -InputObject "Apple VPP Push certificate has already expired, sending notification email"
                            Send-O365MailMessage -Credential $AzureAutomationCredentialName -Body "ACTION REQUIRED: Apple VPP Push certificate has expired" -Subject "MSIntune: IMPORTANT - Apple VPP Push certificate has expired" -Recipient $MailRecipient -From $MailFrom
                        }
                        else {
                            $AppleVPPPushCertificateDaysLeft = ($AppleVPPPushCertificateExpirationDate - (Get-Date))
                            if ($AppleVPPPushCertificateDaysLeft.Days -le $AppleVPPPushCertificateNotificationRange) {
                                Write-Output -InputObject "Apple VPP Push certificate has not expired, but is within the given expiration notification range"
                                Send-O365MailMessage -Credential $AzureAutomationCredentialName -Body "Please take action before the Apple VPP Push certificate expires in $($AppleVPPPushCertificateDaysLeft.Days) days in Directory $($TenantName)" -Subject "MSIntune: Apple VPP Push certificate expires in $($AppleVPPPushCertificateDaysLeft.Days) days in Directory $($TenantName)" -Recipient $MailRecipient -From $MailFrom
                            }
                            else {
                                Write-Output -InputObject "Apple VPP Push certificate has not expired and is outside of the specified expiration notification range"
                            }
                        }
                    }
                    else {
                        Write-Output -InputObject "Query for Apple VPP Push certificates returned empty"
                    }    
                }
                catch [System.Exception] {
                    Write-Warning -Message "An error occurred. Error message: $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning -Message "An error occurred while attempting to retrieve an authentication token"
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "Failed to retrieve authentication token"
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "Failed to read automation variables"
    }
}
catch [System.Exception] {
    Write-Warning -Message "Failed to import modules"
}