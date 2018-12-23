## Add new Mail alias to ad users


$Domains = "mydomain01.com","mydomain02.net"
$ou = “OU=Users,DC=mydomain02,DC=net”
Get-ADUser -SearchBase “OU=ITA,OU=Users,OU=ITR,DC=itr,DC=lan” -Filter * -Properties mail | foreach-object {
    $Proxies = @("SMTP:$($_.mail)")
    $Proxies += foreach ($Domain in $Domains)
    {
        "smtp:$($_.mail.split('@')[0])@$Domain"
    }
    ## Will delete all existings mail alias. Do a "-append" insted of "-replace"
    $_ | Set-ADuser -replace @{ProxyAddresses = $Proxies}
}