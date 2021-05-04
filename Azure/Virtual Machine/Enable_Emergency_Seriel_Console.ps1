<#
##*===============================================
##* START - DESCRIPTION
##*===============================================    
Follow the below steps to enable Emergency Management Service (Seriel Console)

Step 1: logon to the Azure VM.
Step 2: Run CMD as Administrator and run the follow line: 
    Bcdedit /ems {current} on
Step 3: Restart Azure VM
Step 4: Enable Boot diagnostics on the Azure VM (Use a custom boot diagnostic account, not managed)
Step 5: Enable Serial Console in your subsciprtion, run the lines below in CloudShell: 

subscriptionId=$(az account show --output=json | jq -r .id)
az resource invoke-action --action enableConsole --ids "/subscriptions/$subscriptionId/providers/Microsoft.SerialConsole/consoleServices/default" --api-version="2018-05-01"

Follow the below steps to access PowerShell in  Emergency management Service (Seriel Console)

Step 1: Go to "seriel Console" tab on the Azure VM in Azure portal.
Step 2: type: 
    cmd
Step 3: type: 
    ch -si 1
Step 4: Authenticate with an local administrator account
Step 5: Type: 
    PowerShell.exe

##*===============================================
##* END - DESCRIPTION
##*===============================================
#>
