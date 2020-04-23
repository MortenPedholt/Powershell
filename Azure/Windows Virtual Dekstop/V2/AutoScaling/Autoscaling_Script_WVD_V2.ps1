$AADTenantId = ""
$SubscriptionID = ""

$HostPoolResourceGroupName = ""
$Location = ""
$HostpoolName = ""
$BeginPeakTime = ""
$EndPeakTime = ""
$TimeDifference = ""
$SessionThresholdPerCPU = ""
$MinimumNumberOfRDSH = ""

$MaintenanceTagName = "noscaling"


$AutomationAccountName = ""
$ConnectionAssetName = "AzureRunAsConnection"


#Get time

function Convert-UTCtoLocalTime
{
	param(
		$TimeDifferenceInHours
	)

	$UniversalTime = (Get-Date).ToUniversalTime()
	$TimeDifferenceMinutes = 0
	if ($TimeDifferenceInHours -match ":") {
		$TimeDifferenceHours = $TimeDifferenceInHours.Split(":")[0]
		$TimeDifferenceMinutes = $TimeDifferenceInHours.Split(":")[1]
	}
	else {
		$TimeDifferenceHours = $TimeDifferenceInHours
	}
	#Azure is using UTC time, justify it to the local time
	$ConvertedTime = $UniversalTime.AddHours($TimeDifferenceHours).AddMinutes($TimeDifferenceMinutes)
	return $ConvertedTime
}


##Login

	#Collect the credentials from Azure Automation Account Assets
	$Connection = Get-AutomationConnection -Name $ConnectionAssetName

	#Authenticating to Azure
	Clear-AzContext -Force
	$AZAuthentication = Connect-AzAccount -ApplicationId $Connection.ApplicationId -TenantId $AADTenantId -CertificateThumbprint $Connection.CertificateThumbprint -ServicePrincipal
	if ($AZAuthentication -eq $null) {
		Write-Output "Failed to authenticate Azure: $($_.exception.message)"
		exit
	} else {
		$AzObj = $AZAuthentication | Out-String
		Write-Output "Authenticating as service principal for Azure. Result: `n$AzObj"
	}
	#Set the Azure context with Subscription
	$AzContext = Set-AzContext -SubscriptionId $SubscriptionID
	if ($AzContext -eq $null) {
		Write-Error "Please provide a valid subscription"
		exit
	} else {
		$AzSubObj = $AzContext | Out-String
		Write-Output "Sets the Azure subscription. Result: `n$AzSubObj"
	}


#Loadbalancer
function UpdateLoadBalancerTypeInPeakandOffPeakwithBredthFirst {
		param(
			[string]$HostpoolLoadbalancerType,
			#[string]$TenantName,
            #[string]$HostPoolResourceGroupName,
            #[string]$Location,
			#[string]$HostpoolName,
			[int]$MaxSessionLimitValue
		)
		if ($HostpoolLoadbalancerType -ne "BreadthFirst") {
			Write-Output "Changing hostpool load balancer type:'BreadthFirst' Current Date Time is: $CurrentDateTime"
			$EditLoadBalancerType = Set-AzWvdHostPool -Name $hostpoolname -ResourceGroupName $HostPoolResourceGroupName -Location $location -LoadBalancerType "BreadthFirst" -MaxSessionLimit $MaxSessionLimitValue
			if ($EditLoadBalancerType.LoadBalancerType -eq 'BreadthFirst') {
				Write-Output "Hostpool load balancer type in peak hours is 'BreadthFirst Load Balancing'"
			}
		}

	}


##check for new connections


function Check-ForAllowNewConnections
	{
		param(
			#[string]$HostpoolName,
            #[string]$HostPoolResourceGroupName,
			#[string]$SessionHostName
		)

		# Check if the session host is allowing new connections
        $sessionhosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName
        #foreach ($session in $sessionhosts) {

        $session = $sessionhosts.Name.Split("/")
        $SessionHostName = $session[1]

         $StateOftheSessionHost = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $SessionHostName
		if (!($StateOftheSessionHost.AllowNewSession)) {
			Update-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $SessionHostName -AllowNewSession:$True
		}



		

	}



#Start session host


	function Start-SessionHost
	{
		param(
			[string]$VMName
		)
		try {
			Get-AzVM | Where-Object { $_.Name -eq $VMName } | Start-AzVM -AsJob | Out-Null
		}
		catch {
			Write-Error "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)"
			exit
		}

	}


#Stop session host


	function Stop-SessionHost
	{
		param(
			[string]$VMName
		)
		try {
			Get-AzVM | Where-Object { $_.Name -eq $VMName } | Stop-AzVM -Force -AsJob | Out-Null
		}
		catch {
			Write-Error "Failed to stop Azure VM: $($VMName) with error: $($_.exception.message)"
			exit
		}
	}

###Check if host is available
	function Check-IfSessionHostIsAvailable
	{
		param(
			#[string]$TenantName,
			#[string]$HostpoolName,
            #[string]$HostPoolResourceGroupName,
			[string]$Name
		)
		$IsHostAvailable = $false
		while (!$IsHostAvailable) {
			$SessionHostStatus = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $Name
			if ($SessionHostStatus.Status -eq "Available") {
				$IsHostAvailable = $true
			}
		}
		return $IsHostAvailable
	}

#Converting date time from UTC to Local
$CurrentDateTime = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifference



#Check PEAK TIME AND MORE!


$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

#check the calculated end time is later than begin time in case of time zone
	if ($EndPeakDateTime -lt $BeginPeakDateTime) {
		$EndPeakDateTime = $EndPeakDateTime.AddDays(1)
	}



#Checking givne host pool name exists in Tenant
	$HostpoolInfo = Get-AzWvdHostPool -Name $HostpoolName -ResourceGroupName $HostPoolResourceGroupName
	if ($HostpoolInfo -eq $null) {
		Write-Output "Hostpoolname '$HostpoolName' does not exist. Ensure that you have entered the correct values."
		exit
	}



# Setting up appropriate load balacing type based on PeakLoadBalancingType in Peak hours
	$HostpoolLoadbalancerType = $HostpoolInfo.LoadBalancerType
	[int]$MaxSessionLimitValue = $HostpoolInfo.MaxSessionLimit
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		UpdateLoadBalancerTypeInPeakandOffPeakwithBredthFirst -HostPoolName $HostpoolName -MaxSessionLimitValue $MaxSessionLimitValue -HostpoolLoadbalancerType $HostpoolLoadbalancerType
	}
	else {
		UpdateLoadBalancerTypeInPeakandOffPeakwithBredthFirst -HostPoolName $HostpoolName -MaxSessionLimitValue $MaxSessionLimitValue -HostpoolLoadbalancerType $HostpoolLoadbalancerType
	}
	Write-Output "Starting WVD tenant hosts scale optimization: Current Date Time is: $CurrentDateTime"
	# Check the after changing hostpool loadbalancer type
	$HostpoolInfo = Get-AzWvdHostPool -Name $HostpoolName -ResourceGroupName $HostPoolResourceGroupName

	# Check if the hostpool have session hosts
	$ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -ErrorAction Stop | Sort-Object Name
	if ($ListOfSessionHosts -eq $null) {
		Write-Output "Session hosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?."
		exit
	}




#Check if it during peak hours

if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime)
	{
		Write-Output "It is in peak hours now"
		Write-Output "Starting session hosts as needed based on current workloads."

		# Peak hours check and remove the MinimumnoofRDSH value dynamically stored in automation variable 												   
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			Remove-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName
		}
		# Check the number of running session hosts
		[int]$NumberOfRunningHost = 0
		# Total of running cores
		[int]$TotalRunningCores = 0
		# Total capacity of sessions of running VMs
		$AvailableSessionCapacity = 0
		#Initialize variable for to skip the session host which is in maintenance.
		$SkipSessionhosts = 0
		$SkipSessionhosts = @()

		$HostPoolUserSessions = Get-AzWvdUserSessionHostPoolLevel -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName

		foreach ($SessionHost in $ListOfSessionHosts) {
            $SessionHost = $SessionHost.Name.Split("/")
            $SessionHost = $SessionHost[1]
			$SessionHostName = $SessionHost

			#$SessionHostName = $SessionHost.SessionHostName | Out-String
			$VMName = $SessionHostName.Split(".")[0]
			# Check if VM is in maintenance
			$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
			if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
				Write-Output "Session host is in maintenance: $VMName, so script will skip this VM"
				$SkipSessionhosts += $SessionHost
				continue
			}
			#$AllSessionHosts = Compare-Object $ListOfSessionHosts $SkipSessionhosts | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
			$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }

			Write-Output "Checking session host: $($SessionHost.SessionHostName | Out-String)  of sessions: $($SessionHost.Sessions) and status: $($SessionHost.Status)"
			if ($SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
				# Check if the Azure vm is running       
				if ($RoleInstance.PowerState -eq "VM running") {
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					# Calculate available capacity of sessions						
					$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
					$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
					[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
				}
			}
		}
		Write-Output "Current number of running hosts:$NumberOfRunningHost"
		if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
			Write-Output "Current number of running session hosts is less than minimum requirements, start session host ..."
			# Start VM to meet the minimum requirement            
			foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
				# Check whether the number of running VMs meets the minimum or not
				if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
					$VMName = $SessionHost.Split(".")[0]
					$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
					if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {
						# Check if the Azure VM is running and if the session host is healthy
						$SessionHostInfo = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $SessionHost
						if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {
							# Check if the session host is allowing new connections
							Check-ForAllowNewConnections -HostPoolName $HostpoolName  -ResourceGroupName $HostPoolResourceGroupName -SessionHostName $SessionHost
							# Start the Az VM
							Write-Output "Starting Azure VM: $VMName and waiting for it to complete ..."
							Start-SessionHost -VMName $VMName

							# Wait for the VM to Start
							$IsVMStarted = $false
							while (!$IsVMStarted) {
								$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name -eq $VMName }
								if ($RoleInstance.PowerState -eq "VM running") {
									$IsVMStarted = $true
									Write-Output "Azure VM has been Started: $($RoleInstance.Name) ..."
								}
							}
							# Wait for the VM to start
							$SessionHostIsAvailable = Check-IfSessionHostIsAvailable -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHost $SessionHost
							if ($SessionHostIsAvailable) {
								Write-Output "'$SessionHost' session host status is 'Available'"
							}
							else {
								Write-Output "'$SessionHost' session host does not configured properly with deployagent or does not started properly"
							}
							# Calculate available capacity of sessions
							$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
							$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
							[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
							[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
							if ($NumberOfRunningHost -ge $MinimumNumberOfRDSH) {
								break;
							}
						}
					}
				}
			}
		}
		else {
			#check if the available capacity meets the number of sessions or not
			Write-Output "Current total number of user sessions: $(($HostPoolUserSessions).Count)"
			Write-Output "Current available session capacity is: $AvailableSessionCapacity"
			if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
				Write-Output "Current available session capacity is less than demanded user sessions, starting session host"
				# Running out of capacity, we need to start more VMs if there are any 
				foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
					if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
						$VMName = $SessionHost.Split(".")[0]
						$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }

						if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {
							# Check if the Azure VM is running and if the session host is healthy
							$SessionHostInfo = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $SessionHost
							if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {
								# Validating session host is allowing new connections
								Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHostName $SessionHost
								# Start the Az VM
								Write-Output "Starting Azure VM: $VMName and waiting for it to complete ..."
								Start-SessionHost -VMName $VMName
								# Wait for the VM to Start
								$IsVMStarted = $false
								while (!$IsVMStarted) {
									$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name -eq $VMName }
									if ($RoleInstance.PowerState -eq "VM running") {
										$IsVMStarted = $true
										Write-Output "Azure VM has been Started: $($RoleInstance.Name) ..."
									}
								}
								$SessionHostIsAvailable = Check-IfSessionHostIsAvailable-HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHost $SessionHost
								if ($SessionHostIsAvailable) {
									Write-Output "'$SessionHost' session host status is 'Available'"
								}
								else {
									Write-Output "'$SessionHost' session host does not configured properly with deployagent or does not started properly"
								}
								# Calculate available capacity of sessions
								$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
								$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
								[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
								[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
								Write-Output "New available session capacity is: $AvailableSessionCapacity"
								if ($AvailableSessionCapacity -gt $HostPoolUserSessions.Count) {
									break
								}
							}
							#Break # break out of the inner foreach loop once a match is found and checked
						}
					}
				}
			}
		}
	}
	

 
else
	{
		Write-Output "It is Off-peak hours"
		Write-Output "Starting to scale down WVD session hosts ..."
		Write-Output "Processing hostpool $($HostpoolName)"
		# Check the number of running session hosts
		[int]$NumberOfRunningHost = 0
		# Total number of running cores
		[int]$TotalRunningCores = 0
		#Initialize variable for to skip the session host which is in maintenance.
		$SkipSessionhosts = 0
		$SkipSessionhosts = @()
		
        $ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName
		foreach ($SessionHost in $ListOfSessionHosts) {
            
             $SessionHost = $SessionHost.Name.Split("/")
             $SessionHost = $SessionHost[1]
			$SessionHostName = $SessionHost
			$VMName = $SessionHostName.Split(".")[0]
			$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
			# Check the session host is in maintenance
			if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
				Write-Output "Session host is in maintenance: $VMName, so script will skip this VM"
				$SkipSessionhosts += $SessionHost
				continue
			}
			# Maintenance VMs skipped and stored into a variable
			$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }
			if ($SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
				# Check if the Azure VM is running
				if ($RoleInstance.PowerState -eq "VM running") {
					Write-Output "Checking session host: $($SessionHost.SessionHostName | Out-String)  of sessions:$($SessionHost.Sessions) and status:$($SessionHost.Status)"
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					# Calculate available capacity of sessions  
					$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
					[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
				}
			}
		}
		# Defined minimum no of rdsh value from webhook data
		[int]$DefinedMinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH
		## Check and Collecting dynamically stored MinimumNoOfRDSH value																 
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			[int]$MinimumNumberOfRDSH = $OffPeakUsageMinimumNoOfRDSH.Value
		}


		# Breadth first session hosts shutdown in off peak hours
		if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
			foreach ($SessionHost in $AllSessionHosts) {
				#Check the status of the session host
				if ($SessionHost.Status -ne "Unavailable") {
					if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
						$SessionHostName = $SessionHost.Name.Split("/")
                        $SessionHostName = $SessionHostName[1]
						$VMName = $SessionHostName.Split(".")[0]
						if ($SessionHost.Session -eq 0) {
							# Shutdown the Azure VM, which session host have 0 sessions
							Write-Output "Stopping Azure VM: $VMName and waiting for it to complete ..."
							Stop-SessionHost -VMName $VMName

                            #wait for the VM to stop
                        $IsVMStopped = $false
						while (!$IsVMStopped) {
							$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name -eq $VMName }
							if ($RoleInstance.PowerState -eq "VM deallocated") {
								$IsVMStopped = $true
								Write-Output "Azure VM has been stopped: $($RoleInstance.Name) ..."
							}
						}


                        $IsSessionHostNoHeartbeat = $false
						while (!$IsSessionHostNoHeartbeat) {
							$SessionHostInfo = Get-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $SessionHostName
							if ($SessionHostInfo.UpdateState -eq "Succeeded" -and $SessionHostInfo.Status -eq "Unavailable") {
								$IsSessionHostNoHeartbeat = $true
								# Ensure the Azure VMs that are off have allow new connections mode set to True
								if ($SessionHostInfo.AllowNewSession -eq $false) {
									Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHostName $SessionHostName
								}
							}
						}
						$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
						#decrement number of running session host
						[int]$NumberOfRunningHost = [int]$NumberOfRunningHost - 1
						[int]$TotalRunningCores = [int]$TotalRunningCores - $RoleSize.NumberOfCores



                            
						}
						else {
                    Write-Output "Sessionhost $VMName have active connections not doing anything with them"

					#Drain mode
				<#		
                            # Ensure the running Azure VM is set as drain mode
							try {
								$KeepDrianMode = Update-AzWvdSessionHost -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -Name $SessionHostName -AllowNewSession:$false -ErrorAction Stop
							}
							catch {
								Write-Output "Unable to set it to allow connections on session host: $SessionHostName with error: $($_.exception.message)"
								#exit
							}
                            
							# Notify user to log off session
							# Get the user sessions in the hostpool
							try {
								$HostPoolUserSessions = Get-AzWvdUserSessionHostPoolLevel -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName | Where-Object { $_.Name -eq $SessionHostName }
							}
							catch {
								Write-Output "Failed to retrieve user sessions in hostpool: $($Name) with error: $($_.exception.message)"
								#exit
							}
							$HostUserSessionCount = ($HostPoolUserSessions | Where-Object -FilterScript { $_.Name -eq $SessionHostName }).Count
							Write-Output "Counting the current sessions on the host $SessionHostName :$HostUserSessionCount"
							$ExistingSession = 0
							foreach ($session in $HostPoolUserSessions) {
								if ($session.SessionHostName -eq $SessionHostName -and $session.SessionState -eq "Active") {
									if ($LimitSecondsToForceLogOffUser -ne 0) {
										# Send notification
										try {
											Send-AzWvdUserSessionMessage -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHostName $SessionHostName -UserSessionId $session.SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt -ErrorAction Stop
										}
										catch {
											Write-Output "Failed to send message to user with error: $($_.exception.message)"
											#exit
										}
										Write-Output "Script was sent a log off message to user: $($Session.UserPrincipalName | Out-String)"
									}
								}
								$ExistingSession = $ExistingSession + 1
							}
							# Wait for n seconds to log off user
							Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

							if ($LimitSecondsToForceLogOffUser -ne 0) {
								# Force users to log off
								Write-Output "Force users to log off ..."
								foreach ($Session in $HostPoolUserSessions) {
									if ($Session.SessionHostName -eq $SessionHostName) {
										#Log off user
										try {
											Disconnect-AzWvdUserSession -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHostName $Session.SessionHostName -SessionId $Session.SessionId -NoUserPrompt -ErrorAction Stop
											$ExistingSession = $ExistingSession - 1
										}
										catch {
											Write-Output "Failed to log off user with error: $($_.exception.message)"
											#exit
										}
										Write-Output "Forcibly logged off the user: $($Session.UserPrincipalName | Out-String)"
									}
								}
							}
							# Check the session count before shutting down the VM
							if ($ExistingSession -eq 0) {
								# Shutdown the Azure VM
								Write-Output "Stopping Azure VM: $VMName and waiting for it to complete ..."
								Stop-SessionHost -VMName $VMName
				 		}#>	
						}
   
		}
				}
			}
		}
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			[int]$MinimumNumberOfRDSH = $OffPeakUsageMinimumNoOfRDSH.Value
			$NoConnectionsofhost = 0
			if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
				foreach ($SessionHost in $AllSessionHosts) {
					if ($SessionHost.Status -eq "Available" -and $SessionHost.Session -eq 0) {
						$NoConnectionsofhost = $NoConnectionsofhost + 1
					}
				}
				if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
					[int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
					Set-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH
				}
			}
		}
		$HostpoolMaxSessionLimit = $HostpoolInfo.MaxSessionLimit
		$HostpoolSessionCount = (Get-AzWvdUserSessionHostPoolLevel -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName).Count
		if ($HostpoolSessionCount -ne 0)
		{
			# Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor
			$TotalAllowSessionsInOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
			$SessionsScaleFactor = $TotalAllowSessionsInOffPeak * 0.90
			$ScaleFactor = [math]::Floor($SessionsScaleFactor)

			if ($HostpoolSessionCount -ge $ScaleFactor) {
				$ListOfSessionHosts = Get-AzWvdSessionHost -HostPoolName $hostpoolname -ResourceGroupName $HostPoolResourceGroupName | Where-Object { $_.Status -eq "NoHeartbeat" }
				#$AllSessionHosts = Compare-Object $ListOfSessionHosts $SkipSessionhosts | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
				$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }
				foreach ($SessionHost in $AllSessionHosts) {
					# Check the session host status and if the session host is healthy before starting the host
					if ($SessionHost.UpdateState -eq "Succeeded") {
						Write-Output "Existing sessionhost sessions value reached near by hostpool maximumsession limit need to start the session host"
						$SessionHostName = $SessionHost.SessionHostName | Out-String
						$VMName = $SessionHostName.Split(".")[0]
						# Validating session host is allowing new connections
						Check-ForAllowNewConnections -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHostName $SessionHost.SessionHostName
						# Start the Az VM
						Write-Output "Starting Azure VM: $VMName and waiting for it to complete ..."
						Start-SessionHost -VMName $VMName
						#Wait for the VM to start
						$IsVMStarted = $false
						while (!$IsVMStarted) {
							$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name -eq $VMName }
							if ($RoleInstance.PowerState -eq "VM running") {
								$IsVMStarted = $true
								Write-Output "Azure VM has been started: $($RoleInstance.Name) ..."
							}
						}
						# Wait for the sessionhost is available
						$SessionHostIsAvailable = Check-IfSessionHostIsAvailable -HostPoolName $HostpoolName -ResourceGroupName $HostPoolResourceGroupName -SessionHost $SessionHost.SessionHostName
						if ($SessionHostIsAvailable) {
							Write-Output "'$($SessionHost.SessionHostName | Out-String)' session host status is 'Available'"
						}
						else {
							Write-Output "'$($SessionHost.SessionHostName | Out-String)' session host does not configured properly with deployagent or does not started properly"
						}
						# Increment the number of running session host
						[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
						# Increment the number of minimumnumberofrdsh
						[int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH + 1
						$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
						if ($OffPeakUsageMinimumNoOfRDSH -eq $null) {
							New-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH -Description "Dynamically generated minimumnumber of RDSH value"
						}
						else {
							Set-AzAutomationVariable -Name "OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH
						}
						# Calculate available capacity of sessions
						$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
						$AvailableSessionCapacity = $TotalAllowSessions + $HostpoolInfo.MaxSessionLimit
						[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
						Write-Output "New available session capacity is: $AvailableSessionCapacity"
						break
					}
				}
			}

		}

}
	
	Write-Output "HostpoolName: $HostpoolName, TotalRunningCores: $TotalRunningCores NumberOfRunningHosts: $NumberOfRunningHost"
	Write-Output "End WVD tenant scale optimization."