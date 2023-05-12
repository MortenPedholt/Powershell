#With authentication

$From = "" # eg. test@pedholtlab.com
$To = "" # eg. test@pedholtlab.com
$SMTPServer = "" # eg. smtp.pedholtlab.com
$SMTPPort = "587"
$Username = "" # eg. test@pedholtlab.com
$Password = "" # Password for test user
$subject = "Test mail from smtp powershell script"
$body = "Test mail from smtp powershell script"
$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
$smtp.Send($From, $To, $subject, $body)


#Without authentication

$From = "" # eg. test@pedholtlab.com
$To = "" # eg. test@pedholtlab.com
$SMTPServer = "smtp.sendgrid.net" # eg. smtp.pedholtlab.com
$SMTPPort = "25"
$subject = "Test mail from smtp powershell script"
$body = "Test mail from smtp powershell script"
$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
#$smtp.EnableSSL = $true
#$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
$smtp.Send($From, $To, $subject, $body)
