#File location
$File = "C:\temp\testfile01.txt"

#Choose container name must exist
$containerName = "test"

#Choose Destination folder, it will create one if you specifive a folder that dosent exist
$DestinationFolder = "Folder01"

#Choose between 1-20 connections at time
$ConcurrentTasks = "1"

#Can be "Cool", "Hot" or "Archive"
$BlobTier = "Archive"


	$ErrorActionPreference = "Stop"

	$StorageAccountName = "YourStorageAccountKey"
	$StorageAccountKey = "YourStorageAccountKey"

	$missingFiles = New-Object Collections.Generic.List[string]
	

	# Can find all files in subfolders
	#foreach ($singleFile in $File) {
	#	if ($_.psiscontainer){$_.fullname}	(write-host "$singleFile findes") }



	# make sure all files exist
	foreach ($singleFile in $File) {
		if(-not (Test-Path $singleFile)) {
			$missingFiles.Add($singleFile)
		}
	} #foreach
	
	# if files are missing, throw error
	if($missingFiles.Count -gt 0) {
		$errstr = $missingFiles | Format-List | Out-String
		Write-Error "Files to upload do not exist: `n$errstr" 
	}#
	
	$StorageAccountContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
	

	foreach ($singleFile in $File) {
		$fileName = Split-Path -Path $singleFile -Leaf
		
		$blobName = "$DestinationFolder/$fileName"
		write-host "copying $fileName to $blobName"
		
		# upload file
		$blobResult = Set-AzureStorageBlobContent -File $singleFile -Container $containerName -Blob $blobName `
			-Context $storageAccountContext -ConcurrentTaskCount $ConcurrentTasks
	
		if($blobResult -ne $null) {
			# if file uploaded correctly, change to specified tier
			$blobResult.ICloudBlob.SetStandardBlobTier($BlobTier)
			Get-AzureStorageBlob -Container $containerName -Blob $blobName -Context $storageAccountContext | Format-List
		} else {
			# if file didn't upload, throw error
			Write-Error "Upload of $fileName failed."
		}
	} #foreach
