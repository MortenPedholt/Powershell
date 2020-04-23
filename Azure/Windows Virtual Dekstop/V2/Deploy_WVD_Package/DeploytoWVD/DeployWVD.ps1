#Check if path exist, else create
$OutputPath = "C:\DeployWVD\"
$StorageAccountName = ""

$path = $OutputPath
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}


$Logpath = $OutputPath
start-Transcript -Path "$Logpath\DeployWVD_Log_$(get-date -f yyyy-MM-dd).txt" -IncludeInvocationHeader -Append -Force -Verbose

#PARAMETERS
Write-Host "Reading parameters..." -ForegroundColor Cyan
$SourceURL = "https://$StorageAccountName.blob.core.windows.net/dev/DeploytoWVD/DeploymentContent/"

$AgentScript = "InstallAgents.ps1"
$RDBootLoader = "Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
$RDAgent = "Microsoft.RDInfra.RDAgent.Installer-x64-1.0.1288.2700.msi"
$Registrationkey = "RegistrationKey.txt"
$CheckVariableScript = "CheckSystemVariables.ps1"

#Download Agentscript
Write-Host "Downloading Agent Script..." -ForegroundColor Cyan

$url = $SourceURL + $AgentScript
$output = $OutputPath + $AgentScript

Invoke-WebRequest -Uri $url -OutFile $output -Verbose

#Download CheckVariableScript
Write-Host "Downloading Check variable Script..." -ForegroundColor Cyan

$url = $SourceURL + $CheckVariableScript
$output = $OutputPath + $CheckVariableScript

Invoke-WebRequest -Uri $url -OutFile $output -Verbose


#Download RD Boot Loader
Write-Host "Downloading RD Boot Loader.." -ForegroundColor Cyan

$url = $SourceURL + $RDBootLoader
$output = $OutputPath + $RDBootLoader

Invoke-WebRequest -Uri $url -OutFile $output -Verbose

#Download RD Agent
Write-Host "Downloading RD Agent..." -ForegroundColor Cyan -Verbose

$url = $SourceURL + $RDAgent
$output = $OutputPath + $RDAgent

Invoke-WebRequest -Uri $url -OutFile $output -Verbose

#Download WVD Regristration Key
Write-Host "Downloading WVD RegistrationK Key..." -ForegroundColor Cyan

$url = $SourceURL + $Registrationkey
$output = $OutputPath + $Registrationkey

Invoke-WebRequest -Uri $url -OutFile $output -Verbose

#Execute AgentDeployment

Invoke-Expression $OutputPath$AgentScript -Verbose
Write-Host "Executing script $AgentScript..." -ForegroundColor Cyan

Write-Host "End of script" -ForegroundColor Cyan

#Execute CheckVariableScript

Invoke-Expression $OutputPath$CheckVariableScript -Verbose
Write-Host "Executing script $CheckVariableScript..." -ForegroundColor Cyan

Write-Host "End of script" -ForegroundColor Cyan

Stop-Transcript