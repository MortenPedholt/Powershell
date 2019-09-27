#
#Change UPN Suffix on AD Users.
#
$oldSuffix = "@Scandistandard.com"
$newSuffix = "@naapurinmaalaiskana.fi"
$ou = "OU=Users,DC=domain,DC=local"
$server = "DKSCANARSDC2"
Get-ADUser -identity $ou| ForEach-Object {
$newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
$_ | Set-ADUser -Server $server -UserPrincipalName $newUpn
}