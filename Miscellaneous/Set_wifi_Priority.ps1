 $listProfiles = netsh wlan show profiles | Select-String -Pattern "All User Profile" | %{ ($_ -split ":")[-1].Trim() };
    $All = $listProfiles | foreach {
	$profileInfo = netsh wlan show profiles name=$_ key="clear";
	$SSID = $profileInfo | Select-String -Pattern "SSID Name" | %{ ($_ -split ":")[-1].Trim() };
    If ($SSID -eq '"Pedholtlab Wifi"') {
    netsh wlan set profileorder name="Pedholtlab Wifi" interface="Wi-Fi" priority=1
    }
	
		
	}
