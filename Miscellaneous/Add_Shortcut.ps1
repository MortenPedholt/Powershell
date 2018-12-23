#Create new shortcut

$MakeShortcurFrom = "D:\Origin\Origin.exe"
$ShortcutDestination = "$env:USERPROFILE\Desktop\ShortcutTest.lnk"


$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$ShortcutDestination")
$Shortcut.TargetPath = "$MakeShortcurFrom"
$Shortcut.Save()