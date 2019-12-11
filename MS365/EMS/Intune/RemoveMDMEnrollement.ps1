$MDMEnrollment = "https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Enrollments\"

foreach ($Path in $RegPath) { 
    Get-ChildItem $Path -Recurse |
    ForEach-Object { 
        $Key = $_
       $CheckKeyPath = if (($Key.GetValueNames() | % { $Key.GetValue($_) }) -eq $MDMEnrollment) {  
            Write-Host $Key
            
            Remove-Item -Path Registry::$Key -Recurse
            
                       
            if ($CheckKeyPath) {
            Write-Host "Not every key have been deleted, continue to remove keys" -ForegroundColor Cyan }
            else
            { Write-Host "$Key has been deleted, ending foreach loop" -ForegroundColor Cyan
              Break
            }
        } 
    } 
}

