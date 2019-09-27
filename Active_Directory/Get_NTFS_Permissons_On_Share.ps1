$path = “\\share\someting”
$pathparts = $path.split("\")
$ComputerName = $pathparts[2]
$ShareName = $pathparts[3]
 
Write-Host " $path"
Write-Host
 
$acl = Get-Acl $path
 
Write-Host "File/NTFS Permissions"
Write-Host
 
foreach($accessRule in $acl.Access)
{
    Write-Host "   " $accessRule.IdentityReference $accessRule.FileSystemRights
}
Write-Host
Write-Host "Share/SMB Permissions"
Write-Host
 
    $Share = Get-WmiObject win32_LogicalShareSecuritySetting -Filter "name='$ShareName'" -ComputerName $ComputerName
    if($Share){
        $obj = @()
        $ACLS = $Share.GetSecurityDescriptor().Descriptor.DACL
        foreach($ACL in $ACLS){
            $User = $ACL.Trustee.Name
            if(!($user)){$user = $ACL.Trustee.SID}
            $Domain = $ACL.Trustee.Domain
            switch($ACL.AccessMask)
            {
                2032127 {$Perm = "Full Control"}
                1245631 {$Perm = "Change"}
                1179817 {$Perm = "Read"}
            }
            Write-Host "   $Domain\$user  $Perm"
        }
    }