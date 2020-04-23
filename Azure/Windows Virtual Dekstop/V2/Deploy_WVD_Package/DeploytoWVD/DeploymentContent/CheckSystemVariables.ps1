$Executionpath = "C:\DeployWVD\"
start-Transcript -Path "$Executionpath\CheckSystemVariable_Log_$(get-date -f yyyy-MM-dd).txt" -IncludeInvocationHeader -Append -Force -Verbose

$Hostpoolname = ""
$HostpoolResourcegroup = ""

$Hostname = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

#$MONITORING_AGENT_CLUSTER
$VariableName = "MONITORING_AGENT_CLUSTER"
$value = "EUS2R0C100"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)
Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_AGENT_RING
$VariableName = "MONITORING_AGENT_RING"
$value = "R0"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)
Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}

#$MONITORING_CONFIG_VERSION
$VariableName = "MONITORING_CONFIG_VERSION"
$value = "1.3"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)
Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}



#$MONITORING_DATA_DIRECTORY
$VariableName = "MONITORING_DATA_DIRECTORY"
$value = "C:\windows\system32\config\systemprofile\AppData\Roaming\Microsoft\Monitoring"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)
Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_ENV
$VariableName = "MONITORING_ENV"
$value = "PROD"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)
Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_ACCOUNT
$VariableName = "MONITORING_GCS_ACCOUNT"
$value = "RDSAgentProd"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)
Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_AUTH_ID
$VariableName = "MONITORING_GCS_AUTH_ID"
$value = "RDSAgentPROD.geneva.keyvault.RDSAGENT.WVD"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_AUTH_ID_TYPE
$VariableName = "MONITORING_GCS_AUTH_ID_TYPE"
$value = "AuthKeyVault"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_CERTSTORE
$VariableName = "MONITORING_GCS_CERTSTORE"
$value = "LOCAL_MACHINE\MY"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_ENVIRONMENT
$VariableName = "MONITORING_GCS_ENVIRONMENT"
$value = "Diagnostics Prod"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_NAMESPACE
$VariableName = "MONITORING_GCS_NAMESPACE"
$value = "RDSAgentProd"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


#$MONITORING_GCS_REGION
$VariableName = "MONITORING_GCS_REGION"
$value = "westeurope"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}



#$MONITORING_MDM_ACCOUNT
$VariableName = "MONITORING_MDM_ACCOUNT"
$value = "RDSAgentProd"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}





#$MONITORING_TENANT
$VariableName = "MONITORING_TENANT"
$value = "PROD"
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}

#$MONITORING_RESOURCE
$VariableName = "MONITORING_RESOURCE"
$value = $HostpoolResourcegroup
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}



#$MONITORING_ROLE
$VariableName = "MONITORING_ROLE"
$value = $Hostpoolname
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}

#$MONITORING_ROLE_INSTANCE
$VariableName = "MONITORING_ROLE_INSTANCE"
$value = $Hostname
$Type = "Machine"
$Checkvariable = [Environment]::GetEnvironmentVariable($VariableName, $Type)

Write-Host "Checking enironment variable $VariableName .." -ForegroundColor Cyan

if (-not $Checkvariable){

Write-Host "Enironment variable is not set, setting variable $VariableName .." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable($VariableName, $value, $Type)

}else {

Write-Host "Enironment variable for $VariableName is already set" -ForegroundColor Cyan

}


$TaskName = "GenevaTask"
Write-Host "Checking if GenevaTask schedule task is created"
$GetTask = Get-ScheduledTask | Where-Object { $_.TaskName -like "$($TaskName)*" }
if ($GetTask) {
    Write-Host "Found Schedule Task job $($GetTask).TaskName" -ForegroundColor Cyan
    Write-Host "Startin Task $($GetTask).TaskName" -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $GetTask.TaskName

}else{

    Write-Host "Could not find any task named $TaskName" -ForegroundColor Cyan


}

Write-Host "End of script" -ForegroundColor Cyan


Stop-Transcript