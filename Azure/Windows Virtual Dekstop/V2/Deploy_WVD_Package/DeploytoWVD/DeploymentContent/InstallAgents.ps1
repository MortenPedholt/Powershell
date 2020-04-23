$Executionpath = "C:\DeployWVD"

start-Transcript -Path "$Executionpath\InstallAgents_Log_$(get-date -f yyyy-MM-dd).txt" -IncludeInvocationHeader -Append -Force -Verbose

#Get WVD registrationtoken
Write-Host "Get WVD Registrationtoken..." -ForegroundColor Cyan
$RegistrationToken = Get-Content "$Executionpath\RegistrationKey.txt"


#Install Bootloader Agent
Write-Host "Installing RD Boot Loader..." -ForegroundColor Cyan
$bootloaderinstaller = "$Executionpath\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi"
$agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $bootloaderinstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* $Executionpath\RDBootloader_Log_$(get-date -f yyyy-MM-dd).txt" -Wait -Passthru -Verbose

#Install RD Agent
Write-Host "Installing RD Agent..." -ForegroundColor Cyan
$AgentInstaller = "$Executionpath\Microsoft.RDInfra.RDAgent.Installer-x64-1.0.1288.2700.msi"
$agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* $Executionpath\RDAgent_Log_$(get-date -f yyyy-MM-dd).txt" -Wait -Passthru -Verbose


Stop-Transcript