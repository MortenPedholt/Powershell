# Connect to MSOL
Write-Host "Connecting MSOL Online" -ForegroundColor Green
Connect-MsolService -Credential (Get-Credential -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
if (Get-MsolDomain) { Write-Host "Conneced to O365 MSOL Online" -ForegroundColor Green} else {Write-Host "Can't Connect to O365 Online, exiting." -ForegroundColor Red ;exit}

# Get all MFA Enabled users
Write-Host "Collecting Enabled MFA Users from MSOnline" -ForegroundColor Green
$MFAUsers = Get-Msoluser -all | Where-Object {$_.StrongAuthenticationMethods -like "*"}

if ($MFAUsers) { Write-Host "Found $($MFAUsers.Count) Users which are enabled for MFA" -ForegroundColor Green } else {Write-Host "No MFA Users were found, exiting." -ForegroundColor Red; exit}

# Setting Array to gather Users Information
$Results = @()
$UserCounter = 1

# Running on MFA Enabled All Users
Write-Host "Processing Invdividual Users, please wait" -ForegroundColor Green
foreach ($User in $MFAUsers)
{
    Write-Host "Processing #$UserCounter Out Of #$($MFAUsers.Count): Working on User $($User.UserPrincipalName)" -ForegroundColor Cyan
    $UserCounter +=1
    
    $StrongAuthenticationRequirements = $User | Select-Object -ExpandProperty StrongAuthenticationRequirements
    $StrongAuthenticationUserDetails = $User | Select-Object -ExpandProperty StrongAuthenticationUserDetails
    $StrongAuthenticationMethods = $User | Select-Object -ExpandProperty StrongAuthenticationMethods
 
    $Results += New-Object PSObject -property @{ 
    DisplayName = $User.DisplayName -replace "#EXT#","" 
    UserPrincipalName = $user.UserPrincipalName -replace "#EXT#","" 
    IsLicensed = $user.IsLicensed
    MFAState = $StrongAuthenticationRequirements.State
    RememberDevicesNotIssuedBefore = $StrongAuthenticationRequirements.RememberDevicesNotIssuedBefore
    StrongAuthenticationUserDetailsPhoneNumber = $StrongAuthenticationUserDetails.PhoneNumber
    StrongAuthenticationUserDetailsEmail = $StrongAuthenticationUserDetails.Email
    DefaultStrongAuthenticationMethodType = ($StrongAuthenticationMethods | Where {$_.IsDefault -eq $True}).MethodType
    }
}

# Select Users Details and export to CSV
Write-Host "Exoprting Details to CSV..." -ForegroundColor Green
$Results | Select-Object `
            DisplayName, `
            UserPrincipalName, `
            IsLicensed, `
            StrongAuthenticationUserDetailsPhoneNumber, `
            DefaultStrongAuthenticationMethodType `
            | Export-Csv -NoTypeInformation .\MFAEnabledUsers-$(Get-Date -Format "yyyy-MM-dd").csv -Force