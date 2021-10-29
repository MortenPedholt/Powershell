 #Requires -Module Microsoft.Graph.Intune

 #Service Principal needs the following API Permissions:
 
#DeviceManagementApps.Read.All - type:Application 
#DeviceManagementServiceConfig.Read.All - type:Application 


###############################################################################################

# treshold days before expiration notification is fired
$AppleMDMPushCertificateNotificationRange = 365

# Read credentials and variables
        Write-Output -InputObject "Reading SMTP Properties"
        $MailTo = "IT@domain.com"
        $MailFrom = "No-Reply@domain.com"

$AzureAutomationCredentialName = "MSIntuneAutomationUser"
$Credential = Get-AutomationPSCredential -Name $AzureAutomationCredentialName -ErrorAction Stop


# Microsoft Teams Webhook URI
#$webHookUri = "https://outlook.office.com/webhook/7d5dcaef-5326-43a3-b83d-b601e19a5bd6@7955e1b3-cbad-49eb-9a84-e14aed7f3400/IncomingWebhook/0795975319dd4509b9c9f74a0f1de68f/36c9b091-fe88-4dc2-a9e1-2662020b4bab"

# Connect to Microsoft Graph (option #1 via service principal)
#$servicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection" -ErrorAction Stop
#Update-MSGraphEnvironment -AuthUrl "https://login.microsoftonline.com/$($servicePrincipalConnection.TenantId)" -AppId $servicePrincipalConnection.ApplicationId
#Connect-MSGraph -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint -Quiet

# Connect to Microsoft Graph (option #2 via application & client secret)
Write-Output "Loggin in Microsoft Graph"
    $tenant = Get-AutomationVariable -Name TenantId
    $authority = "https://login.windows.net/$tenant"
    $clientId = Get-AutomationVariable -Name AppClientID
    $clientSecret = Get-AutomationVariable -Name AppClientSecret
    Update-MSGraphEnvironment -AppId $clientId -Quiet
    Update-MSGraphEnvironment -AuthUrl $authority -Quiet
    Connect-MSGraph -ClientSecret $ClientSecret -Quiet


# Connect to Microsoft Graph (option #3 via credentials)
<#
    $creds = Get-AutomationPSCredential -Name ""
    Connect-MSGraph -Credential $creds -Quiet
#>

###############################################################################################


# Add configured days to current date for treshold comparison
Write-Output "Get notificationtreshold date"
$notificationTreshold = (Get-Date).AddDays($notificationTresholdDays)

# Process Apple push notification certificate and check for expiration
Write-Output "Getting information about Apple MDM Push Certificate"
$applePushNotificationCertificate = Get-DeviceManagement_ApplePushNotificationCertificate

$AppleMDMPushCertificateExpirationDate = $applePushNotificationCertificate.expirationDateTime

if ($AppleMDMPushCertificateExpirationDate -lt (Get-Date)) {
                            Write-Output -InputObject "Apple MDM Push certificate has already expired, sending notification email"
                            Write-Output -InputObject "Sending Email message to $MailTo"
                            #Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Body "ACTION REQUIRED: Intune Apple MDM Push certificate has expired" -Subject "MSIntune: IMPORTANT - Apple MDM Push certificate has expired" -Credential $Credential -UseSsl
                        }
                        else {
                            $AppleMDMPushCertificateDaysLeft = ($AppleMDMPushCertificateExpirationDate - (Get-Date))
                            if ($AppleMDMPushCertificateDaysLeft.Days -le $AppleMDMPushCertificateNotificationRange) {
                                Write-Output -InputObject "Apple MDM Push certificate has not expired, but is within the given expiration notification range, there is $($AppleMDMPushCertificateDaysLeft.Days) Days Left"
                                Write-Output -InputObject "Sending Email message to $MailTo"
                                #Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Body "Please take action before the Intune Apple MDM Push certificate expires. It will expire in $($AppleMDMPushCertificateDaysLeft.Days) days" -Subject "MSIntune: Apple MDM Push certificate expires in $($AppleMDMPushCertificateDaysLeft.Days) days" -Credential $Credential -UseSsl                           
                                 }
                            else {
                                Write-Output -InputObject "Apple MDM Push certificate has not expired and is outside of the specified expiration notification range"
                            }
                        }




Write-Output "Getting information about Apple VPP Tokens"

# Process all Apple vpp tokens and check if they will expire soon
$appleVppTokens = Get-DeviceAppManagement_VppTokens

$appleVppTokens | ForEach-Object {

    $appleVppToken = $PSItem

    $appleVppTokenExpirationDate = $appleVppToken.expirationDateTime

                        if ($appleVppTokenExpirationDate -lt (Get-Date)) {
                            Write-Output -InputObject "Apple VPP Token has already expired, sending notification email"
                            Write-Output -InputObject "Sending Email message to $MailTo"
                            #Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Body "ACTION REQUIRED: Intune Apple VPP Token has expired. VPP Token ID is:$($appleVppToken.vppTokenId)" -Subject "MSIntune: IMPORTANT - Apple VPP Token has expired" -Credential $Credential -UseSsl
                        }
                        else {
                            $AppleVPPCertificateDaysLeft = ($appleVppTokenExpirationDate - (Get-Date))
                            if ($AppleVPPCertificateDaysLeft.Days -le $AppleMDMPushCertificateNotificationRange) {
                                Write-Output -InputObject "Apple VPP Token has not expired, but is within the given expiration notification range, there is $($AppleVPPCertificateDaysLeft.Days) Days Left. VPP Token ID is:$($appleVppToken.vppTokenId)"
                                Write-Output -InputObject "Sending Email message to $MailTo"
                                #Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Body "Please take action before the Intune Apple MDM Push certificate expires. It will expire in $($AppleVPPCertificateDaysLeft.Days) days. VPP Token ID is:$($appleVppToken.vppTokenId)" -Subject "MSIntune: Apple VPP Token expires in $($AppleVPPCertificateDaysLeft.Days) days" -Credential $Credential -UseSsl                           
                                 }
                            else {
                                Write-Output -InputObject "Apple VPP Token has not expired and is outside of the specified expiration notification range. VPP Token ID is:$($appleVppToken.vppTokenId)"
                            }
                        }


# Process all Apple DEP Tokens (we have to switch to the beta endpoint)
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
#Connect-MSGraph -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint -Quiet
Connect-MSGraph -ClientSecret $ClientSecret -Quiet

$appleDepTokens = (Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/depOnboardingSettings").value
Write-Output "Getting information about Apple DEP Tokens"

$appleDepTokens | ForEach-Object {

    $appleDepToken = $PSItem

               $appleDEPTokenExpirationDate = $appleDepToken.TokenExpirationDateTime

                        if ($appleDEPTokenExpirationDate -lt (Get-Date)) {
                            Write-Output -InputObject "Apple DEP Token has already expired, sending notification email"
                            Write-Output -InputObject "Sending Email message to $MailTo"
                            #Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Body "ACTION REQUIRED: Intune Apple DEP Token has expired. DEP Token ID is:$($appleDepToken.id)" -Subject "MSIntune: IMPORTANT - Apple DEP Token has expired" -Credential $Credential -UseSsl
                        }
                        else {
                            $AppleDEPCertificateDaysLeft = ($appleDEPTokenExpirationDate - (Get-Date))
                            if ($AppleDEPCertificateDaysLeft.Days -le $AppleMDMPushCertificateNotificationRange) {
                                Write-Output -InputObject "Apple DEP Token has not expired, but is within the given expiration notification range, there is $($AppleDEPCertificateDaysLeft.Days) Days Left. DEP Token ID is:$($appleDepToken.id)"
                                Write-Output -InputObject "Sending Email message to $MailTo"
                                #Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To $MailTo -From $MailFrom -Body "Please take action before the Intune Apple MDM Push certificate expires. It will expire in $($AppleDEPCertificateDaysLeft.Days) days. DEP Token ID is:$($appleDepToken.id)" -Subject "MSIntune: Apple VPP Token expires in $($AppleDEPCertificateDaysLeft.Days) days" -Credential $Credential -UseSsl                           
                                 }
                            else {
                                Write-Output -InputObject "Apple DEP Token has not expired and is outside of the specified expiration notification range. VPP Token ID is:$($appleDepToken.id)"
                            }
                        }

    }

}
    
  
