$MDMEnrollment = "https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Enrollments\"
 
foreach ($CurrentPath in $RegPath) { 
    Get-ChildItem $CurrentPath -Recurse |  
    ForEach-Object { 
        $Key = $_
        if (($Key.GetValueNames() | % { $Key.GetValue($_) }) -eq $MDMEnrollment) {  
            Write-Host $Key
            Remove-Item -Path Registry::$Key -Recurse
        } 
    } 
}