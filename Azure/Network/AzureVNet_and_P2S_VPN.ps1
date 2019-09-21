<#
.DESCRIPTION
##*===============================================
##* START - DESCRIPTION
##*===============================================    

Create Azure Vnet and Virtual network Gateway, to establish Point-to-site connection.

Script author: Morten Pedholt
Script created on: November 2019
Script edited date: 
Script last edited by: 
Script version: 1.0.0
##*===============================================
##* END - DESCRIPTION
##*===============================================

#>


##*===============================================
##* START - VARIABLES
##*===============================================

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]    
    [string]$modulename = 'Az',
    [Parameter(Mandatory=$false)]    
    [string]$logpath = ''
    [Parameter(Mandatory=$true)]    
    [string]$Location = 'West Europe'
    [Parameter(Mandatory=$true)]    
    [string]$ResourceGroupName = 'TestRG'
    [Parameter(Mandatory=$true)]    
    [string]$VnetName = 'Vnetname'
    [Parameter(Mandatory=$true)]    
    [string]$VnetAddressprefix = '192.168.4.0/24'
    [Parameter(Mandatory=$true)]    
    [string]$SubnetName01 = 'FrontEnd'
    [Parameter(Mandatory=$true)]    
    [string]$SubnetName01Addressprefix = '192.168.4.0/26'
    [Parameter(Mandatory=$false)]    
    [string]$SubnetName02 = ''
    [Parameter(Mandatory=$false)]    
    [string]$SubnetName02Addressprefix = ''
    [Parameter(Mandatory=$false)]    
    [string]$SubnetName03 = ''
    [Parameter(Mandatory=$false)]    
    [string]$SubnetName03Addressprefix = ''
    [Parameter(Mandatory=$true)]    
    [string]$GatewaySubnet = 'GatewaySubnet'
    [Parameter(Mandatory=$true)]    
    [string]$GatewaySubnetAddressprefix = '192.168.4.192/26'
    [Parameter(Mandatory=$true)]    
    [string]$VpnclientAddresspool = '192.168.104.0/24'
    [Parameter(Mandatory=$true)]    
    [string]$PublicIPGatewaySubnetName = 'PointToSite-PublicIP'
    [Parameter(Mandatory=$true)]    
    [string]$VPNGatewayName = 'VPNGatewayName'
    [Parameter(Mandatory=$true)]    
    [string]$VPNGatewaySku = 'VpnGw1'
    [Parameter(Mandatory=$true)]    
    [string]$VPNGatewayType = 'RouteBased'

	
)

##*===============================================
##* END - VARIABLES
##*===============================================


##*===============================================
##* START - CHECK FOR LOGGIN IN SCRIPT
##*===============================================

#Start transcript if logpath is defined
if ($logpath) {
    If(!(test-path $logpath)) {
            New-Item -ItemType Directory -Force -Path $logpath  -Verbose

    } else{
        Write-Host "$logpath Directory already exist" -ForegroundColor Cyan
        
    }

 Start-Transcript -Path $logpath\Pedholtlab_$(get-date -f yyyy-MM-dd).txt -IncludeInvocationHeader -Append -Force -Verbose
    }else {
    Write-Host "No logpath is specificed in variables" -ForegroundColor Cyan
}
##*===============================================
##*  END - CHECK FOR LOGGIN IN SCRIPT
##*===============================================


##*===============================================
##*  START - CHECK IF REQUIRED MODULE IS INSTALLED
##*===============================================

#Check if the required module is installed, if not it will install and import the module.
if ($modulename) {
    $checkmodule = Get-Module -ListAvailable | Where-Object { $_.Name -like $modulename } -Verbose
    if($checkmodule) {
    Write-Host "$modulename is already installed" -ForegroundColor Cyan
    Import-Module $checkmodule.Name
    }
    Else{
    Write-Host "$modulename is not installed, installing $modulename module" -ForegroundColor Green
    Install-Module $modulename -AllowClobber -Verbose
    Import-Module $modulename
    }

} else {
    Write-Host "No module requirements is specificed in variables" -ForegroundColor Cyan
}

##*===============================================
##*  END - CHECK IF REQUIRED MODULE IS INSTALLED
##*===============================================

##*===============================================
##* START - SCRIPT BODY
##*===============================================

#Connect to Azure
Connect-AzAccount

#Check if Resourcegroup is created, if not it will be created
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if(!$ResourceGroup)
{
    Write-Host "Resource group '$ResourceGroupName' does not exist.";
    if(!$Location) {
        $resourceGroupLocation = Read-Host "Provide location for a new ResourceGroup";
    }
    Write-Host "Creating resource group '$ResourceGroupName' in location '$Location'";
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}
else{
    Write-Host "resource group '$ResourceGroupName' already exist";
}


#New Virtual network
New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $VnetName -Location $Location `
-AddressPrefix $VnetAddressprefix -Verbose

#Add Virtual Subnets
$Vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VnetName

Add-AzVirtualNetworkSubnetConfig -Name $SubnetName01 `
-VirtualNetwork $Vnet -AddressPrefix $SubnetName01Addressprefix -Verbose

Add-AzVirtualNetworkSubnetConfig -Name $SubnetName02 `
-VirtualNetwork $Vnet -AddressPrefix $SubnetName02Addressprefix -Verbose -ErrorAction SilentlyContinue

Add-AzVirtualNetworkSubnetConfig -Name $SubnetName03 `
-VirtualNetwork $Vnet -AddressPrefix $SubnetName03Addressprefix -Verbose -ErrorAction SilentlyContinue

Add-AzVirtualNetworkSubnetConfig -Name $GatewaySubnet `
-VirtualNetwork $Vnet -AddressPrefix $GatewaySubnetAddressprefix -Verbose

#Save the network configuration
Set-AzVirtualNetwork -VirtualNetwork $Vnet -Verbose

#Create Virtual NetworkGateway
$Vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VnetName
$PublicIp = New-AzPublicIpAddress -Name $PublicIPGatewaySubnetName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic -Verbose
$Subnet = Get-AzVirtualNetworksubnetConfig -name $GatewaySubnet -VirtualNetwork $Vnet
$ipconf = New-AzVirtualNetworkGatewayIpConfig -Name GW -Subnet $Subnet -PublicIpAddress $PublicIp -Verbose
New-AzVirtualNetworkGateway -Name $VPNGatewayName -ResourceGroupName $ResourceGroupName -Location $Location -IpConfigurations $Ipconf -GatewayType Vpn `
-VpnType $VPNGatewayType -EnableBgp $false -GatewaySku $VPNGatewaySku -VpnClientAddressPool $VPNClientAddressPool -Verbose


<#
#Generete Root Certeficat
$filepathforcert = "C:\cert\P2SRootCert"
$P2SRootCertName = "P2SRootCert.cer"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature -Subject "CN=P2SRootCert" `
-KeyExportPolicy Exportable -HashAlgorithm sha256 -KeyLength 2048 -CertStoreLocation `
"Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

#See current Certeficate on currentuser
Get-ChildItem -Path “Cert:\CurrentUser\My”

#Generete Child Certeficat - Put in your own thumbprint
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My\"Thumbprint""
New-SelfSignedCertificate -Type Custom -KeySpec Signature ` -Subject "CN=P2SChildCert" -KeyExportPolicy Exportable ` -HashAlgorithm sha256 -KeyLength 2048 ` -CertStoreLocation "Cert:\CurrentUser\My" ` -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") 

#>


##*===============================================
##* END - SCRIPT BODY
##*===============================================


#Stop Transcript if it's startet
try{
    stop-transcript | out-null
  }
  catch [System.InvalidOperationException]{}



##*===============================================
##* END - CHECK FOR LOGGIN IN SCRIPT
##*===============================================
