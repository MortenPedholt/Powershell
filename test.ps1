$filepathforcert = "C:\cert\P2SRootCert"
$P2SRootCertName = "P2SRootCert.cer"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject "CN=P2SRootCert" `
-KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation `
"Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

$cert = Get-ChildItem -Path "Cert:\CurrentUser\My\DBD49B5C76892B15EA27FF360B3B9BE66C05151D"
New-SelfSignedCertificate -Type Custom -KeySpec Signature ` -Subject "CN=P2SChildCert" -KeyExportPolicy Exportable ` -HashAlgorithm sha256 -KeyLength 2048 ` -CertStoreLocation "Cert:\CurrentUser\My" ` -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") 


Connect-AzAccount

$gw = Get-AzVirtualNetworkGateway -Name vpn-gateway -ResourceGroupName PROD-WEU-Network01
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -VpnClientRootCertificates @()
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -AadTenantUri "https://login.microsoftonline.com/df83a75f-cd14-4504-9c07-896ba2ec319f" -AadAudienceId "41b23e61-6c1e-4545-b367-cd054e0ed4b4" -AadIssuerUri "https://sts.windows.net/df83a75f-cd14-4504-9c07-896ba2ec319f/"


$profile = New-AzVpnClientConfiguration -Name vpn-gateway -ResourceGroupName PROD-WEU-Network01 -AuthenticationMethod "EapTls"
$PROFILE.VpnProfileSASUrl