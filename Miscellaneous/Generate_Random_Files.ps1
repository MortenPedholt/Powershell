#This script will generate random text files with GUID as name in your current directory folder.


Add-Type -AssemblyName System.web;
 
function GenerateRandomFile{
param (
    $Filename,
    $FileSize
)
 
$block = 128
 
if ($FileSize -lt $block) {$FileSize = $block}
 
(1..($FileSize/$block)).foreach({-join ([system.web.security.membership]::GeneratePassword($block,0))}) | Set-Content $FileName
 
}
 
 
function GenerateMultibleFiles{
param (
    $NumberOfFiles,
    $FileSize
)    
 
    for ($x=1; $x -lt $NumberOfFiles; $x++) 
        { 
            $FileName = "$([guid]::NewGuid()).txt"
            "$FileName : $((Measure-Command {GenerateRandomFile -Filename "$([guid]::NewGuid()).txt" -FileSize $FileSize}).TotalSeconds)"
        }
 
} 
 

#Specify how many files and size you would like to generate.
GenerateMultibleFiles -NumberOfFiles 10 -FileSize 10mb   