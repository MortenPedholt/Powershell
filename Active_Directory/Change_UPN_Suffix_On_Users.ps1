#
#Change UPN Suffix on AD Users.
#
$oldSuffix = "@olddomain.com"
$newSuffix = "@newdomain.com"
$ou = "OU=Users,DC=domain,DC=local"
$server = "servername"
Get-ADUser -identity $ou| ForEach-Object {
$newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
$_ | Set-ADUser -Server $server -UserPrincipalName $newUpn
}
