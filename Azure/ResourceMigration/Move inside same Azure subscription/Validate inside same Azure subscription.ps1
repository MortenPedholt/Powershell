<#  
.SYNOPSIS  
Function which validates resource move between resource groups inside same Azure subscription.  
  
.DESCRIPTION  
Wrapper function around Azure API https://docs.microsoft.com/en-us/rest/api/resources/resources/validatemoveresources  
Function is building all necessary parts to send a properly formated query as a web request via API and validate the resource move between resource groups indside same Azure subscription.  
ARM will report if the resources can be migrated or there are dependencies which have to be resolved.  
  
.PARAMETER ApplicationId  
ID of the service principal/application which will be used to validate the resource move, keep in mind that it has to have proper rights.  
  
.PARAMETER ApplicationPassword  
Password of the service principal/application.  
  
.PARAMETER TenantID 
Tenant ID where your service principal live.

.PARAMETER SourceSubscriptionID 
Subscription ID of the source subscription

.PARAMETER SourceResourceGroup  
Name of the resource group where resources are located.  
  
.PARAMETER DestinationResourceGroup  
Name of the resource group to where you want to move the resources.  
  
#>  


#######################
# Start Parameters
#######################

#Service Principal Login
$ApplicationId = ''  
$ApplicationPassword = Convertto-SecureString -String '' -AsPlainText -Force

#Tenant ID
$TenantID = ""

#Source details
$SourceSubscriptionID = ""
$SourceResourceGroup = ""

#Destination details
$DestinationResourceGroup = ""

#######################
# End Parameters
#######################

Function Get-AzAccessToken { 
    [CmdletBinding()] 
    param( 
        [Parameter(Mandatory = $True, 
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True, 
            HelpMessage = 'Provide Client Id or Application Id from Azure AD or any Microsoft API.')] 
        [string]$ClientId, 
        [Parameter(Mandatory = $True, 
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True, 
            HelpMessage = 'Provide Client Secret provided from Azure AD or any Microsoft API.')] 
        [securestring]$ClientSecret, 
        [Parameter(Mandatory = $True, 
            ValueFromPipeline = $True, 
            ValueFromPipelineByPropertyName = $True, 
            HelpMessage = 'Provide Microsoft Azure API Login URL.')] 
        [string]$ApiUri 
    ) 
    process { 
        $GrantType = 'client_credentials' 
        $TargetResource = 'https://management.core.windows.net/' 
        $ClientSecret2 = $([System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($ClientSecret)))
        $body = "grant_type=$GrantType&client_id=$ClientId&client_secret=$ClientSecret2&resource=$TargetResource" 
        $response = Invoke-RestMethod -Method Post -Uri $ApiUri -Body $body -ContentType 'application/x-www-form-urlencoded' 
        return $response 
    } 
}  

Function Get-AzResourceMoveValidation { 
    [CmdletBinding()] 
    param ( 
         # ID of the Source Subscription ID.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourceSubscriptionID,
        # ID of the service principal/application. 
        [Parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()] 
        [string]$ApplicationId, 
        # Password of the service principal. 
        [Parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()] 
        [securestring]$ApplicationPassword, 
        # Name of the source resource group. 
        [Parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()] 
        [string]$SourceResourceGroup, 
        # Name of the target resource group. 
        [Parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()] 
        [string]$TargetResourceGroup 
    ) 
    process { 
        $TenantId = (Get-AzContext | Select-Object -ExpandProperty Tenant).Id 
        $SubscriptionId = "$SourceSubscriptionID"
        $ApiUrl = "https://login.microsoftonline.com/$TenantId/oauth2/token" 
        $TargetUri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$SourceResourceGroup/validateMoveResources?api-version=2019-08-01" 
        [array]$ResourceList = (Get-AzResource -ResourceGroupName $SourceResourceGroup | Where-Object { $_.ResourceType -match '^[^\/]+\/[^\/]+$' }).ResourceId 
        $TargetId = (Get-AzResourceGroup -Name $TargetResourceGroup).ResourceId 
        $CustomObject = [PSCustomObject]@{ 
            resources           = $ResourceList 
            targetResourceGroup = $TargetId 
        } 
        $Body = $CustomObject | ConvertTo-Json 
        $TokenSplat = @{ 
            ClientId     = $ApplicationId 
            ClientSecret = $ApplicationPassword
            ApiUri       = $ApiUrl 
        } 
        $Token = Get-AzAccessToken @TokenSplat 
        $Headers = @{ } 
        $Headers.Add("Authorization", "$($Token.token_type) $($Token.access_token)") 
        $RestSplat = @{ 
            Uri         = $TargetUri 
            Method      = 'Post' 
            Headers     = $Headers 
            ContentType = 'application/json' 
            Body        = $Body 
        } 
        try { 
            $ErrorActionPreference = 'Stop' 
            $Capture = Invoke-WebRequest @RestSplat 
            if ($Capture.StatusCode -eq 202) { 
                $RestSplat.Uri = "$($Capture.Headers.location)" 
                $RestSplat.Method = 'Get' 
                $RestSplat.Remove('Body') 
                $RestSplat.Remove('ContentType') 
                $StartCount = 0 
                $RetryCount = 3 
                $SleepTimer = 60 
                while ($StartCount -ne $RetryCount) { 
                    $StartCount++ 
                    Invoke-WebRequest @RestSplat 
                    Start-Sleep -Seconds $SleepTimer 
                } 
            } 
            elseif ($Capture.StatusCode -eq 204) { 
                Write-Host -ForegroundColor Green 'VALIDATION SUCCEEDED, ALL RESOURCES CAN BE MOVED!' 
            } 
            else { 
                $Capture 
            } 
        } 
        catch { 
            Write-Error "$_" -ErrorAction Stop 
        } 
    } 
}

#Login with access Token
$AccessToken = Get-AzAccessToken -ClientId $ApplicationId -ClientSecret $ApplicationPassword -ApiUri "https://login.microsoftonline.com/$TenantID/oauth2/token"
Login-AzAccount -AccessToken $AccessToken.access_token -AccountId $ApplicationId

#Run validation
Get-AzResourceMoveValidation -ApplicationId $ApplicationId -ApplicationPassword $ApplicationPassword `
-SourceSubscriptionID $SourceSubscriptionID -SourceResourceGroup $SourceResourceGroup `
-TargetResourceGroup $DestinationResourceGroup