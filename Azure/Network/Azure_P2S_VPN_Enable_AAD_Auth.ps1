
Connect-AzAccount
$VpnGatewayName = "PROD-WEU-VNG01"
$ResourceGroupName = "PROD-WEU-CoreNetwork-RG"

$gw = Get-AzVirtualNetworkGateway -Name $VpnGatewayName -ResourceGroupName $ResourceGroupName
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -VpnClientProtocol "OpenVPN"
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -VpnClientRootCertificates @()
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -AadTenantUri "https://login.microsoftonline.com/4b667584-0e05-4ae5-9e80-b2dd98806076" -AadAudienceId "41b23e61-6c1e-4545-b367-cd054e0ed4b4" -AadIssuerUri "https://sts.windows.net/4b667584-0e05-4ae5-9e80-b2dd98806076/"


$profile = New-AzVpnClientConfiguration -Name $VpnGatewayName -ResourceGroupName $ResourceGroupName -AuthenticationMethod "EapTls"
$PROFILE.VpnProfileSASUrl