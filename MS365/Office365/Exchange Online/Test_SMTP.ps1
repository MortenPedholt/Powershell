#Test SMTP.
#SMTP with authentication
Send-MailMessage -SmtpServer smtp.office365.com -port 587 -To user@domain.dk -From user@domain.dk -Body "test" -Subject "test" -Credential $cred -UseSsl

#SMTP witour authentication
Send-MailMessage -SmtpServer domain.mail.protection.outlook.com -port 25 -To moped@domain.dk -From test@domain.dk -Body "test" -Subject "test"