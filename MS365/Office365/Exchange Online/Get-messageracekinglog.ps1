Get-MessageTrackingLog -Start (Get-Date).AddHours(-10) -End (Get-Date) -EventId RECEIVE | ? {$_.Source -eq "SMTP"} | Group-Object -Property OriginalClientIp

Get-MessageTrackingLog -Start (Get-Date).AddHours(-10) -End (Get-Date) -EventId RECEIVE | ? {$_.Source -eq "SMTP" -and $_.OriginalClientIP -eq "[Ipaddresse]"}