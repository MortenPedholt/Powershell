#  create secret in secure file
#  secret key from Service Principal Name
#  the following command saves Azure secret key to a file.
#  copy key/secret from Azure Application and paste it to the following command.

read-host -assecurestring | convertfrom-securestring | out-file c:\temp\cred.txt 



# state variables
$tenantId = "b54d1591-7d75-4215-8260-5a0d9763578e"
$appId = "e65140aa-9b55-4bd7-8f4a-19aae4bc42df@zebragroup.onmicrosoft.com"
$secret = get-content -Path "C:\temp\cred.txt" | ConvertTo-SecureString




# set the powershell credential object
$cred = New-Object -TypeName System.Management.Automation.PSCredential($appId ,$secret)

# log On To Azure Account 
Connect-AzureRmAccount -ServicePrincipal -Credential $cred -TenantId $tenantId


##### After this other cmdlets can be executed as required #####
################################################################


# state variables
$connection = Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName "Shared-Infrastructure-Azure" -Name "AzureProdVpnConnection"

write-host $connection.ConnectionStatus -ForegroundColor green
