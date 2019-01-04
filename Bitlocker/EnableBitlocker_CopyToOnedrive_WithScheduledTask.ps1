<# 
DESCRIPTION 
This script will enable bitlocker on the systemdrive and copy the key to onedrive "Recovery" folder with an scheduled task.
The scheduled task will be deleted when the key have been moved from systemdrive\temp to onedrive.
#>

 

[cmdletbinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $OSDrive = $env:SystemDrive
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Create directory is not exist
$psdirectory = "$osdrive\Program Files (x86)\Scripts\Bitlocker"
If(!(test-path $psdirectory))
{
      New-Item -ItemType Directory -Force -Path $psdirectory
}

#Start session log
Start-Transcript -Path $psdirectory\pslogmainscript.txt -Append

try
{

#Check if bitlocker already have a recoverykey, if it dosent it will enable bitlocker and create new recoverykey
$checkifexist = (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}
 if($checkifexist) {
Write-host "Bitlocker is already enabled and have recoverykey"
}
else{

$bdeProtect = Get-BitLockerVolume $OSDrive | Select-Object -Property VolumeStatus

            if ($bdeProtect.VolumeStatus -eq "FullyDecrypted") 
	       {
              # Enable Bitlocker using TPM
            Enable-BitLocker -MountPoint $OSDrive  -TpmProtector -ErrorAction Continue
            Enable-BitLocker -MountPoint $OSDrive  -RecoveryPasswordProtector

	       }
}    

                #Writing recovery key to temp directory, we will move this file to onedrive with scheduled task script later
                New-Item -ItemType Directory -Force -Path "$OSDrive\temp" | out-null
				(Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector   | Out-File "$OSDrive\temp\$($env:computername)_BitlockerRecoveryPassword.txt"

				
                #Check if we can use BackupToAAD-BitLockerKeyProtector commandlet
			    $cmdName = "BackupToAAD-BitLockerKeyProtector"
                if (Get-Command $cmdName -ErrorAction SilentlyContinue)
				{
					#BackupToAAD-BitLockerKeyProtector commandlet exists
					$BLK = (Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'}
					if ($BLK.count -gt 1){

					Write-Host "There are multiple recovery keys, will backup key number 1 to AzureAD"
					$key = $BLK[0]
					BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $key.KeyProtectorId

					}
					else {
						Write-Host "There are only one recovery key, will start to backup to AzureAD"
						BackupToAAD-BitLockerKeyProtector -MountPoint $OSDrive -KeyProtectorId $BLK.KeyProtectorId
					}
					
                }
			    else
                { 

		  		# BackupToAAD-BitLockerKeyProtector commandlet not available, using other mechanisme  
				# Get the AAD Machine Certificate
				$cert = Get-ChildItem Cert:\LocalMachine\My\ | Where-Object { $_.Issuer -match "CN=MS-Organization-Access" }

				# Obtain the AAD Device ID from the certificate
				$id = $cert.Subject.Replace("CN=","")

				# Get the tenant name from the registry
				$tenant = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\$($id)).UserEmail.Split('@')[1]

				# Generate the body to send to AAD containing the recovery information
				# Get the BitLocker key information from WMI
					(Get-BitLockerVolume -MountPoint $OSDrive).KeyProtector| Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} | ForEach-Object{
					$key = $_
					write-verbose "kid : $($key.KeyProtectorId) key: $($key.RecoveryPassword)"
					$body = "{""key"":""$($key.RecoveryPassword)"",""kid"":""$($key.KeyProtectorId.replace('{','').Replace('}',''))"",""vol"":""OSV""}"
				
				# Create the URL to post the data to based on the tenant and device information
					$url = "https://enterpriseregistration.windows.net/manage/$tenant/device/$($id)?api-version=1.0"
				
				# Post the data to the URL and sign it with the AAD Machine Certificate
					$req = Invoke-WebRequest -Uri $url -Body $body -UseBasicParsing -Method Post -UseDefaultCredentials -Certificate $cert
					$req.RawContent

                            }
			}
            #>
    
    } catch 
            {
            write-error "Error while setting up AAD Bitlocker, make sure that you are AAD joined and are running the cmdlet as an admin: $_"
            }



#Create new PS to move file and set contect to move ondrive document from Temp folder to onedrive
if (!(Test-Path "$psdirectory\Move_recoverykey_to_OneDrive.ps1")){

New-Item -ItemType file -Path "$psdirectory\Move_recoverykey_to_OneDrive.ps1"
Set-Content -Path "$psdirectory\Move_recoverykey_to_OneDrive.ps1" -Value '

#Log script events to file
$psdirectory = "$osdrive\Program Files (x86)\Scripts\Bitlocker"
Start-Transcript -Path $psdirectory\pslog.txt -Append

#Move recovery key from temp directory to OneDrive (if configured)
$OSDrive = $env:SystemDrive
$ErrorActionPreference= ''silentlycontinue''
$regValues = Get-ChildItem "hkcu:\SOFTWARE\Microsoft\OneDrive\Accounts\"

ForEach( $regValue in $regValues)
 {

$key = $regValue.name.Replace("HKEY_CURRENT_USER","hkcu:")              
$ODfBAcct =(Get-ItemProperty -Path $key -Name Business).Business
                              
#Creating Business account path
if ( $ODfBAcct -eq "1"){
$path = (Get-ItemProperty -Path $key -Name UserFolder).UserFolder + "\Recovery"}
}                            
if(!(test-path $path)){
 New-Item -ItemType Directory -Force -Path $path | out-null
}
Move-Item -Path "$OSDrive\temp\$($env:computername)_BitlockerRecoveryPassword.txt" -Destination "$($path)\$($env:computername)_BitlockerRecoveryPassword.txt"

#Delete scheduledtask if recoverykey is moved to onedrive.
# Note! Only works if users have permissions to it
if (Test-Path "$($path)\$($env:computername)_BitlockerRecoveryPassword.txt"){
Unregister-ScheduledTask -TaskName "Move Bitlockerkey to Onedrive with task" -Confirm:$false

}

Else {

}	                

stop-transcript
'
}

#Create Scheduled task to execute our ps file "Move_recoverykey_to_OneDrive.ps1".
$taskName = "Move Bitlockerkey to Onedrive with task"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }
if($taskExists) {
Write-host "Scheduled task "$taskName" already exist"
}
else{
$currentloggedonuser = (Get-WMIObject -class Win32_ComputerSystem | Select-Object username).username
$A = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-WindowStyle hidden -ExecutionPolicy bypass -NonInteractive -File ""C:\Program Files (x86)\Scripts\Bitlocker\Move_recoverykey_to_OneDrive.ps1"
$T = New-ScheduledTaskTrigger -Daily -At 10am 
$P = New-ScheduledTaskPrincipal $currentloggedonuser
$S = New-ScheduledTaskSettingsSet
Register-ScheduledTask -TaskName "Move Bitlockerkey to Onedrive with task" -Description "Move Bitlockerkey to Onedrive with task" -Action $A -Principal $P -Trigger $T -Settings $S

}

Stop-Transcript