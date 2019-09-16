[environment]::Version
 $PSVersionTable.CLRVersion
 gci 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | gp -name Version,Release -EA 0 |
  where { $_.PSChildName -match '^(?!S)\p{L}'} | select PSChildName, Version, Release

  
  
  
  Get-WindowsOptionalFeature -Online -FeatureName NetFx3

  Enable-WindowsOptionalFeature -Online -FeatureName NetFx3