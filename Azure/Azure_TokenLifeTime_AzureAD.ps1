#Documentation https://docs.microsoft.com/da-dk/azure/active-directory/active-directory-configurable-token-lifetimes

#The CMD'let is described below:
#New-AzureADPolicy -Definition <Array of Rules> -DisplayName <Name of Policy> -IsOrganizationDefault <boolean> -Type <Policy Type>

Import-module AzureADPreview

#Connect to AzureAD
Connect-AzureAD -Confirm

#List Existing PolicyToken
Get-AzureADPolicy

#See all Webapps/Services the PolicyToken is used appyied on. Replace the <PolicyTokenID> with the Token ID.
Get-AzureADPolicyAppliedObject -Id <PolicyTokenID>

#Add new TokenPolicy
New-AzureADPolicy -Definition @('{"TokenLifetimePolicy":{"Version":1,"MaxInactiveTime":"30.00:00:00","MaxAgeMultiFactor":"until-revoked","MaxAgeSingleFactor":"180.00:00:00"}}') -DisplayName "policyname" -IsOrganizationDefault $false -Type "TokenLifetimePolicy"

#Remove AzureADPolicy Token
Remove-AzureADPolicy -id <PolicyTokenID>

#Add TokenPolicy to ServicePrincipal
#example below:
#Add-AzureADServicePrincipalPolicy -Id 8f4a9b16-26c7-4e7e-81b4-cbcad847aff5 -RefObjectId b9b165c8-39c8-4023-b42c-ec390defe6cf
Add-AzureADServicePrincipalPolicy -Id <ServicePrincialID> -RefObjectId <PolicytokenID>



#Find Object ID for ServicePrincipals
Get-AzureADServicePrincipal

#See existing ServicePrincipalPolicys
Get-AzureADServicePrincipalPolicy -id <ServicePrincialID>

#Remove ServicePrincipalPolicys
Remove-AzureADServicePrincipalPolicy -Id <ServicePrincipalPolicyID>


#Add TokenPolicy to WEBAPP/WEBSERVICE
#example below:
#Add-AzureADServicePrincipalPolicy -Id 8f4a9b16-26c7-4e7e-81b4-cbcad847aff5 -RefObjectId b9b165c8-39c8-4023-b42c-ec390defe6cf
Add-AzureADServicePrincipalPolicy -Id <ApplicationID> -RefObjectId <PolicytokenID>


#Find Object ID for ApplicationPolicys
get-AzureADApplication

#See existing ApplicationPolicys
get-AzureADApplicationPolicy -id <ID of Application>

#Remove ApplicationPolicy
Remove-AzureADApplicationPolicy -Id <ApplicationPolicyID>
