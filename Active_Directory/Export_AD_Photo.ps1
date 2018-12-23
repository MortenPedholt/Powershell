#Export Active Directory pictures.
$directory='C:\ADuserphoto\'

$users =GET-ADUser -filter * –properties thumbnailphoto

foreach($user in $users) {
	if($user.Thumbnailphoto)
	{
		$filename=$directory+$user.samaccountname+'.jpg'
		[System.Io.File]::WriteAllBytes($Filename, $User.Thumbnailphoto)	
	}
}
