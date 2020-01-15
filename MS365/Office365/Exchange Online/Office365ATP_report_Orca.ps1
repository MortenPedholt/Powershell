#Install ORCA module
install-module -name orca

#Connect Exchange online
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking


#Get ORCA report
Get-ORCAReport


#Remove PSSession
Remove-PSSession $Session