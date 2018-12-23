$users = get-msoluser -All
$sta = @()

foreach ($users in $users) {
set-msoluser -userprincipalname $user.userprincipalname -strongauthenticationrequirements $sta
}