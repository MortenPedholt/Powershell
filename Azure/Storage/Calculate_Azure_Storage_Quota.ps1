#Paramerters
$StorageAccountName = ""
$StorageAccountRGName = ""
$StorageAccountShareName = ""
$MaxUserProfileSize = ""
$MinimumFileShareSize = "150" #This cannot be lower than 100 due to limitations on Azure Premium File shares

#Get Storage account information
Write-Verbose "Getting Storage Account information..." -Verbose
$StorageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $StorageAccountRGName

#Connect to Storage share
Write-Verbose "Connect to Azure storage context" -Verbose
#$StorageAccountContext = New-AzStorageContext -StorageAccountName $StorageAccount.StorageAccountName

Write-Verbose "Getting Azure file share information" -Verbose
$Shareinformation = Get-AzStorageShare -Name $StorageAccountShareName -Context $StorageAccount.Context


$GetDirectories = Get-AzStorageFile -ShareName $StorageAccountShareName -Context $StorageAccount.Context


# Calculate new Quota
Write-Verbose "Calculating file share size based on created FSLogix profile folders in filshare and max user profile size" -Verbose
Write-Verbose "Current profile folders in fileshare: $($GetDirectories.Count)" -Verbose
Write-Verbose "Current max user profile size: $MaxUserProfileSize GB" -Verbose

$NewCalcualtedSize = [math]::Ceiling($GetDirectories.Count * $MaxUserProfileSize)
Write-Verbose "New calculated size is $NewCalcualtedSize GB" -Verbose

if ($NewCalcualtedSize -lt $MinimumFileShareSize){
     Write-Verbose "New calculated size is lower than the minimum size requirement of the fileshare" -Verbose
     Write-Verbose "Ending script" -Verbose
     break
}


if ($NewCalcualtedSize -lt $Shareinformation.Quota){

Write-Verbose "New calculated size is lower than the current size, checking if its possible to lower the quota" -Verbose
$NextQuotaChange = $Shareinformation.ShareProperties.NextAllowedQuotaDowngradeTime.LocalDateTime
    $CurrentDate = Get-date
    if ($CurrentDate -lt $NextQuotaChange){
        Write-Verbose "Unable to lower the quota untill $NextQuotaChange " -Verbose
        Write-Verbose "Ending script" -Verbose

    } else {
    
    Write-Verbose "Decresing file share quota from $($Shareinformation.Quota) to $NewCalcualtedSize GB" -Verbose
    #Set new Quota for File share
    Set-AzStorageShareQuota -ShareName $StorageAccountShareName -Context $StorageAccount.Context -Quota $NewCalcualtedSize -Verbose
    
    }



} else {

    Write-Verbose "incresing file share quota from $($Shareinformation.Quota) to $NewCalcualtedSize GB" -Verbose
    Set-AzStorageShareQuota -ShareName $StorageAccountShareName -Context $StorageAccount.Context -Quota $NewCalcualtedSize -Verbose

}