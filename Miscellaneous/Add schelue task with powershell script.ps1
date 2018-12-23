
# Description: install ps script and register scheduled task

# define your PS script here
$content = @"
Out-File -FilePath "C:\Windows\Temp\test.txt" -Encoding unicode -Force -InputObject "Hello World!"
"@
 
# create custom folder and write PS script
$path = $(Join-Path $env:ProgramData CustomScripts)
if (!(Test-Path $path))
{
 New-Item -Path $path -ItemType Directory -Force -Confirm:$false
}
Out-File -FilePath $(Join-Path $env:ProgramData CustomScripts\myScript.ps1) -Encoding unicode -Force -InputObject $content -Confirm:$false
 
# register script as scheduled task
$Time = New-ScheduledTaskTrigger -At 12:00 -Daily
$User = "SYSTEM"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ex bypass -file `"C:\ProgramData\CustomScripts\myScript.ps1`""
Register-ScheduledTask -TaskName "RunCustomScriptDaily" -Trigger $Time -User $User -Action $Action -Force