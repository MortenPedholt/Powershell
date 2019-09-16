# Optional, To get your tenant ID via PowerShell
Connect-msolservice
Get-MSOLCompanyInformation | select objectID

# Install SharePoint PowerShell If needed
Install-Module SharePointPnPPowerShellOnline

# Example https://$tenant.sharepoint.com/sites/$siteName
$tenant = 'Enter your Tenant Name in Here' # xxxx.onmicrosoft.com
$tenantId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' #Tenant ID, can be retrieved from Azure AD or PowerShell under optional.
$siteName = 'sales' #Sharepoint site name
$docLib = 'Enquiries' #Sharepoint Document Library

# Connection
Connect-PnPOnline https://$tenant.sharepoint.com/sites/$siteName -SPOManagementShell

# If you do not have MDA or modern auth then do not use the -SPOManagementShell switch
Connect-PnPOnline https://$tenant.sharepoint.com/sites/$siteName

# Convert Tenant ID
$tenantId = $tenantId -replace '-','%2D'

# Convert Site ID
$PnPSite = Get-PnPSite -Includes Id | select id
$PnPSite = $PnPSite.Id -replace '-','%2D'
$PnPSite = '%7B' + $PnPSite + '%7D'

# Convert Web ID
$PnPWeb = Get-PnPWeb -Includes Id | select id
$PnPWeb = $PnPWeb.Id -replace '-','%2D'
$PnPWeb = '%7B' + $PnPWeb + '%7D'

# Convert List ID
$PnPList = Get-PnPList $docLib -Includes Id | select id
$PnPList = $PnPList.Id -replace '-','%2D'
$PnPList = '%7B' + $PnPList + '%7D'
$PnPList = $PnPList.toUpper()

# Enumerate the Full URL
$FULLURL = 'tenantId=' + $tenantId + '&siteId=' + $PnPSite + '&webId=' + $PnPWeb + '&listId=' + $PnPList + '&webUrl=https%3A%2F%2F' + $tenant + '%2Esharepoint%2Ecom%2Fsites%2F' + $siteName + '&version=1'

# Output the FULL URL To Copy and Paste
Write-Output 'List ID: ' $FULLURL