#This Script will remove all domains except the domains in the parameter "$acceptedDomains"

$users = Get-ADUser -Filter * -Properties proxyAddresses
$acceptedDomains = ("mydomain01.mail.onmicrosoft.com", "mydomina02.com", "mydomain01.com")
foreach ($user in $users)
{
    $userAddresses = $user.proxyAddresses
    foreach($proxyAddr in $userAddresses)
    {
        if($proxyAddr.startswith("smtp:"))
        {
            $validDomain = $false
            foreach($acceptedDomain in $acceptedDomains)
            {
                if($proxyAddr.EndsWith($acceptedDomain))
                {
                    $validDomain = $true
                }
            }
            
            if($validDomain -eq $false)
            {
                Set-ADUser -Identity $user.SamAccountName -Remove @{proxyAddresses=$proxyAddr}
                Write-Host "Removed $proxyAddr From $($user.SamAccountName)"
            }
                       
        }
    }
}