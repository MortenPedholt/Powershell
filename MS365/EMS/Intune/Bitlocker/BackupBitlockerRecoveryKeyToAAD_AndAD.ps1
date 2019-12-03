$blvolumes = Get-BitLockerVolume | where{ ($_.VolumeStatus -ne "FullyDecrypted") -and ($_.VolumeStatus -ne $null) }
		foreach ($blv in $blvolumes)
		{
			if (($blv.VolumeType -eq "OperatingSystem") -or ($blv.VolumeType -eq "Data"))
			{
				$rpp = $blv.KeyProtector | where { $_.KeyProtectorType -eq "RecoveryPassword" }
				foreach ($kp in $rpp)
				{
					try
					{
                        BackupToAAD-BitLockerKeyProtector -MountPoint $blv.MountPoint -keyProtectorId $kp.KeyProtectorId
                        Write-Host "Uploaded key protector for volume $($blv.MountPoint) to Azure AD"
						
					}
					catch
					{
						Write-Host "Error uploading key protector for volume $($blv.MountPoint) : $($Error[0]) to Azure AD"
						Exit
					}
					try
					{
                        Backup-BitLockerKeyProtector -MountPoint $blv.MountPoint -keyProtectorId $kp.KeyProtectorId
                        Write-Host "Uploaded key protector for volume $($blv.MountPoint) to Active Directory"
                    }
					catch
					{
						Write-Host "Error uploading key protector for volume $($blv.MountPoint) : $($Error[0]) to Active Directory"
						Exit
					}
				}
			}
		}