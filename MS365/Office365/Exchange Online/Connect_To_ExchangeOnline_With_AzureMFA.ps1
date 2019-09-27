# connect til exchange online med MFA
#Install this module! https://cmdletpswmodule.blob.core.windows.net/exopsmodule/Microsoft.Online.CSE.PSModule.Client.application
#
Import-Module $((Get-ChildItem -Path $($env:LOCALAPPDATA+"\Apps\2.0\") -Filter Microsoft.Exchange.Management.ExoPowershellModule.dll -Recurse ).FullName|?{$_ -notmatch "_none_"}|select -First 1)
$MFCCPSSession = New-ExoPSSession -ConnectionUri 'https://outlook.office365.com/powershell-liveid'
import-pssession $MFCCPSSession
