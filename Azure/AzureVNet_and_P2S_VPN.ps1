#New ResourceGroup
New-AzResourceGroup -Name TestRG -Location WestEurope

$vnet = Get-AzVirtualNetwork -ResourceGroupName TestRG -Name 'TestVNet' 

#New Virtual Network
New-AzVirtualNetwork -ResourceGroupName TestRG -Name TestVNet `
-AddressPrefix 192.168.4.0/24 -Location WestEurope

#New Virtual Subnet
Add-AzVirtualNetworkSubnetConfig -Name FrontEnd `
-VirtualNetwork $vnet -AddressPrefix 192.168.4.0/26

Add-AzVirtualNetworkSubnetConfig -Name BackEnd `
-VirtualNetwork $vnet -AddressPrefix 192.168.4.64/26

Add-AzVirtualNetworkSubnetConfig -Name DMZ `
-VirtualNetwork $vnet -AddressPrefix 192.168.4.128/26

Add-AzVirtualNetworkSubnetConfig -Name GatewaySubnet `
-VirtualNetwork $vnet -AddressPrefix 192.168.4.192/26

#Save the configuration
set-azVirtualNetwork -VirtualNetwork $vnet

#Create Virtual NetworkGateway
$VPNClientaddresspool = "192.168.104.0/24"
$vnet = Get-AzVirtualNetwork -ResourceGroupName TestRG -Name 'TestVNet'
$pip = New-AzPublicIpAddress -Name 'gatewayip' -ResourceGroupName TestRG -Location WestEurope -AllocationMethod Dynamic
$subnet = get-azVirtualNetworksubnetConfig -name GatewaySubnet -VirtualNetwork $vnet
$ipconf = New-AzVirtualNetworkGatewayIpConfig -Name GW -Subnet $subnet -PublicIpAddress $pip
New-AzVirtualNetworkGateway -Name vpngw -ResourceGroupName TestRG -Location WestEurope -IpConfigurations $ipconf -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku Standard -VpnClientAddressPool $VPNClientAddressPool

#Generete Root Certeficat
$filepathforcert = "C:\cert\P2SRootCert"
$P2SRootCertName = "P2SRootCert.cer"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject "CN=P2SRootCert" `
-KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation `
"Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

#See current Certeficate on currentuser
Get-ChildItem -Path “Cert:\CurrentUser\My”

#Generete Child Certeficat
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My\0843BBC53AE0C3B7E9492B872E91A351A196D14F"
New-SelfSignedCertificate -Type Custom -KeySpec Signature ` -Subject "CN=P2SChildCert" -KeyExportPolicy Exportable ` -HashAlgorithm sha256 -KeyLength 2048 ` -CertStoreLocation "Cert:\CurrentUser\My" ` -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") 