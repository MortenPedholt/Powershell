<#
.SYNOPSIS
  Export all RBAC Roles in All Azure subscriptions
  This script is provided as is

.DESCRIPTION
  Edit the parameters before running the script.
  Connect-Azaccount to login with your credentials.
  
.NOTES
  Version:        1.0
  Author:         Morten Pedholt
  Creation Date:  June 24th 2021
    
.EXAMPLE
  run with parameter -OutputPath C:\temp

#>

#Parameters
Param (
    [Parameter(Mandatory=$true)]    
    [string]$OutputPath = ''
	
)


#Connect to Azure
Connect-AzAccount

#Get Azure Subscriptions and run them in foreach loop
$report = @()
Get-AzSubscription | 
foreach-object {
    #Choose subscription
    Write-Verbose "Changing to Subscription $($_.Name)" -Verbose

    $Context = Set-AzContext -TenantId $_.TenantId -SubscriptionId $_.Id -Force
    $Name     = $_.Name
    $TenantId = $_.TenantId
    $SubId    = $_.SubscriptionId  

    #Getting information about Role Assignments for choosen subscription
    Write-Verbose "Getting information for Role Assignments" -Verbose
    $roles = Get-AzRoleAssignment | Select-Object RoleDefinitionName,DisplayName,SignInName,ObjectId,ObjectType,Scope,
    @{name="TenantId";expression = {$TenantId}},@{name="SubscriptionName";expression = {$Name}},@{name="SubscriptionId";expression = {$SubId}}


         foreach ($role in $roles){
            #            
            $DisplayName = $role.DisplayName
            $SignInName = $role.SignInName
            $ObjectType = $role.ObjectType
            $RoleDefinitionName = $role.RoleDefinitionName
            $AssignmentScope = $role.Scope
            $SubscriptionName = $Context.Subscription.Name
            $subscriptionID = $Context.Subscription.SubscriptionId

            #Check for Custom Role
            $CheckForCustomRole = Get-AzRoleDefinition -Name $RoleDefinitionName
            $CustomRole = $CheckForCustomRole.IsCustom
            
            #New PSObject
            $obj = New-Object -TypeName PSObject
            $obj | Add-Member -MemberType NoteProperty -Name SubscriptionName -value $SubscriptionName
			$obj | Add-Member -MemberType NoteProperty -Name SubscriptionID -value $SubscriptionID			
            
			$obj | Add-Member -MemberType NoteProperty -Name DisplayName -Value $DisplayName
			$obj | Add-Member -MemberType NoteProperty -Name SignInName -Value $SignInName
			$obj | Add-Member -MemberType NoteProperty -Name ObjectType -value $ObjectType
            
            $obj | Add-Member -MemberType NoteProperty -Name RoleDefinitionName -value $RoleDefinitionName
            $obj | Add-Member -MemberType NoteProperty -Name CustomRole -value $CustomRole
			$obj | Add-Member -MemberType NoteProperty -Name AssignmentScope -value $AssignmentScope
            
            
			
			$Report += $obj
           

    }
}

#Export CSV file
Write-Verbose "Exporting CSV file to $OutputPath" -Verbose
$Report | Export-Csv $OutputPath\RBACExport-$(Get-Date -Format "yyyy-MM-dd").csv