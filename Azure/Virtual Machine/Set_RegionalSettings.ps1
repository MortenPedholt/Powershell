$Timezone = "Romance Standard Time"
$GeoID = "61"

Write-Verbose "Setting Timezone to $Timezone" -Verbose
Set-TimeZone -Id $Timezone

#Set country or region
Write-Verbose "Setting region to Denmark" -Verbose
Set-WinHomeLocation -GeoId $GeoID

#Set Data formats
Write-Verbose "Setting Data Formats to danish standard" -Verbose
$Culture = Get-Culture

$culture.DateTimeFormat.AMDesignator = ''
$culture.DateTimeFormat.PMDesignator = ''
$Culture.DateTimeFormat.ShortDatePattern = 'dd-MM-yyyy'
$Culture.DateTimeFormat.LongDatePattern = 'dddd, d MMMM yyyy'
$Culture.DateTimeFormat.ShortTimePattern = 'HH:mm'
$Culture.DateTimeFormat.LongTimePattern = 'HH:mm:ss'
$Culture.DateTimeFormat.FirstDayOfWeek = 'Monday'

Set-Culture $Culture