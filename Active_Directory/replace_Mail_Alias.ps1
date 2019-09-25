## Add new Mail alias to users


$Domains = "mydomain01.com","mydomain02.net"
$ou = “OU=Users,DC=mydomain02,DC=net”
Get-ADUser -SearchBase $ou -Filter * -Properties mail | foreach-object {
    $Proxies = @("SMTP:$($_.mail)")
    $Proxies += foreach ($Domain in $Domains)
    {
        "smtp:$($_.mail.split('@')[0])@$Domain"
    }
    ## Will delete all existings mail alias. Do a "-append" instead of "-replace"
    $_ | Set-ADuser -replace @{ProxyAddresses = $Proxies}
}