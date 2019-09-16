<#	
.SYNOPSIS
    Imports user list from CSV file and then assigns license on Office 365

.PARAMETER InputFile
    Path for the Input CSV file

.PARAMETER SkipLine
    Optional parameter for value of line number to start from in CSV file.
    Does not include count for header row (if you want to skip first user, enter 1)

.PARAMETER StartTranscript
    Switch to start transcript and store in current directory as text file.

.DESCRIPTION
    Takes an input file with the column 'UserPrincipalName' and first assigns a UsageLocation 
    as per the $UsageLocation variable 'hard-coded' into the script.
    Then it assigns license to the Office 365 user according to the $License variable also 'hard-coded'
    into the script in Parameter Declarations section. 

.INPUTS
    InputFile - CSV File with "," delimited attributes. Must include a column with header 
    'UserPrincipalName'

.OUTPUTS
    assign_LicenseO365-Log - TXT file containing list of all items processed successfully
    assign_LicenseO365-Error - TXT file contains list of any errors occured during script runtime
    assign_LicenseO365-Transcript - TXT file contains PowerShell transcript (if StartTranscript is used)
  
.NOTES
    Version:        1.0
    Author:         Sidharth Zutshi
    Creation Date:  16/11/2017
    Change Date:    
    Purpose/Change: 

.EXAMPLE
    PS C:\> .\assign_LicenseO365.ps1 -InputFile Users.csv
    
    Runs script for all users in the input CSV file. Assigns license as specified by $License 
    variable in script

.EXAMPLE
    PS C:\> .\assign_LicenseO365.ps1 -InputFile Users.csv -SkipLine 5

    Skips the first 5 users in the CSV file and assigns license for all remaining users.

.EXAMPLE
    PS C:\> .\assign_LicenseO365.ps1 -InputFile Users.csv -StartTranscript

    Runs script for all users in the input CSV file and outputs PS transcript


---------------------------------------------------------------------------------------#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string]$InputFile = "C:\Users\moped\Desktop\users.csv",
    
    [int]$SkipLine = 0,
    
    [switch]$StartTranscript = $false
    )

$CurrentDate = (Get-Date -Format "dd-MM-yyyy_HH-mm")
$count = 0
$errcount = 0

#region----------------------------------------------[Parameter Declarations]---------------------------------------------------

$OutputLog = ".\assign_LicenseO365-Log_$CurrentDate.txt"
$OutputErrorLog = ".\assign_LicenseO365-Error_$CurrentDate.txt" 
$OutputTranscript = ".\assign_LicenseO365-Transcript_$CurrentDate.txt"
$License = "amalienet:AAD_PREMIUM"                        #Needs to be changed as per your environment SkuID of License
$UsageLocation = "DK"                                     #Needs to be changes as per your usage location

#endregion


#region--------------------------------------------------[Execution Start]-------------------------------------------------------

if ($StartTranscript -eq $True)
{

    Start-Transcript -Path $OutputTranscript
}

#region: Add Header to Log Files and Output
Write-Output "`n`n
Starting script ***assign_LicenseO365*** with parameters set as
------------------------------------------------------
InputFile = $InputFile
License Type = $License
Usage Location = $UsageLocation
StartTranscript = $StartTranscript
Skip Users = $SkipLine
Output Log File = $OutputLog
Output Error Log = $OutputErrorLog
Output Transcript = $OutputTranscript
------------------------------------------------------" 

$Current = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")

$header = "
Script ***assign_LicenseO365*** 
--------------------------------------------------
Started on:  $Current
Input File: $InputFile
License: $License
Skip Users: $SkipLine
"
Write-Verbose "Initializing Log Files and adding Headers..."
$header > $OutputLog
$header > $OutputErrorLog

#endregion

#Connect to Microsoft Online
Connect-MsolService

#Import CSV file into variable for processing
Write-Verbose "Importing CSV File for list of user UPNs..." 
$Items = (Import-CSV $InputFile -ErrorAction Stop | Select-Object -Property UserPrincipalName -Skip $SkipLine) 

#region: Loop to process each mailbox
foreach($Item in $Items)
{

    $Error.Clear()

    try
    {       
        Write-Output "Assigning License to $($Item.UserPrincipalName)"     
        
        #ASSIGN LICENSE TO USER IN $ITEM
        $UPN = $Item.UserPrincipalName
        Write-Verbose "        [Set-MsolUser] -UsageLocation $UsageLocation" 
        Set-MsolUser -UserPrincipalName $UPN -UsageLocation $UsageLocation -ErrorAction Stop
        Write-Verbose "        [Get-MsolUser | Set-MsolUserLicense] -AddLicenses $License"
        Get-MsolUser –UserPrincipalName $UPN | Set-MsolUserLicense -AddLicenses “$License”

        
        if($Error.Count -ne 0)
        {
            Write-Host "[ERROR]: Error in assigning license to user! Please see Output Error Logs for details." `
                -ForegroundColor Red

            $string = "--------------------------------------------------
            User = $($Item.UserPrincipalName)
            Error Details:
            "

            $string >> $OutputErrorLog 
            $Error[0] >> $OutputErrorLog
            $Error[1] >> $OutputErrorLog
            $errcount++
        }
        else
        {
            Write-Host "User Licensed successfully." -ForegroundColor Green
            $string = "--------------------------------------------------
            Item Processed with details:
            User = $($Item.UserPrincipalName)"

            $string >> $OutputLog
            $count++
        }
        $Error.Clear()
    }

    catch
    {
        Write-Host "[ERRORCATCH]: Error in assigning license to user! Please see Output Error Logs for details." `
            -ForegroundColor Red

        $string = "--------------------------------------------------
        User = $($Item.UserPrincipalName)
   
        Error Details:
        "

        $string >> $OutputErrorLog 
        $Error[0] >> $OutputErrorLog
        $Error[1] >> $OutputErrorLog
        $errcount++
    }

    finally
    {
        $TotalCount = $count + $errcount
        if($TotalCount -ne 1)
        {
            $Percent = "{0:N2}" -f ($TotalCount/$Items.count * 100)

            Write-Progress -Activity "Assigning Licenses..." `
	            -Status "Progress: $Totalcount/$($Items.count)   $Percent% " `
	            -PercentComplete $Percent `
	            -CurrentOperation "$($Item.SomeProperty)"
        }
    }
}
#endregion

if ($StartTranscript -eq $True)
{
    Stop-Transcript
}


#endregion


#region------------------------------------------------[End Processing]-----------------------------------------------------------

#region: Add footer to Log files and Output
$CurrentEnd = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
						 
Write-Output "`n`n`n**************************End Script**************************`n`n" 
Write-Output "Script Ended on $CurrentEnd
Total Items Processed = $count
Total Errors = $errcount

"

$footerLog = "
--------------------------------------------------
--------------------------------------------------
********************END SCRIPT********************

Script Ended on: $CurrentEnd
Total Items Processed: $count
"

$footerError = "
--------------------------------------------------
--------------------------------------------------
********************END SCRIPT********************

Script Ended on: $CurrentEnd
Total Errors: $errcount
"
Write-Verbose "Adding Footer to Log Files..."
$footerLog >> $OutputLog
$footerError >> $OutputErrorLog
#endregion

#endregion


#--------------------------------------------------------------***End Script***----------------------------------------------------------
