. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\ContactList.core.ps1"

function Create-ContactLists {
	param (
		[int]$ContactListSize,
		[int]$ChunkSize
	)

	Write-Section "Creating Contact Lists"

	$directoriesWithImages = Get-DirectoriesWithImages
	$totalDirs = $directoriesWithImages.Count
	$currentDir = 1

	$directoriesWithImages | ForEach-Object {
        $directoryPrefix = "[$currentDir/$totalDirs] `"$_`""
        $path = $_.FullName
        $directoryName = $_.Name
		$contactListNamePrefix = "$($_.Name)"

		Write-Log "$directoryPrefix Started processing..."

		$images = Get-SupportedImages "$path" | Sort-Object Name
		$imagePaths = @(Extract-RelativePaths $path $images)

		$contactLists = @()

		for ($i = 0; $i -lt $imagePaths.Count; $i += $ContactListSize) {
			$group = $imagePaths[$i..([math]::Min($i + $ContactListSize - 1, $imagePaths.Count - 1))]
			$contactLists += ,@($group)  # comma ensures each group is added as an array
		}

		$contactListNumber = 1
	
		# Now $contactLists is an array of arrays
		$contactLists | ForEach-Object {
			$contactListName = if ($contactLists.Count -eq 1) { $contactListNamePrefix } else { "$($contactListNamePrefix)_$($contactListNumber)" }

			$contactListChunks = @()
	
			for ($i = 0; $i -lt $_.Count; $i += $ChunkSize) {
				$chunk = $_[$i..([math]::Min($i + $ChunkSize - 1, $_.Count - 1))]
				$contactListChunks += ,@($chunk)  # comma ensures each group is added as an array
			}
			
			$chunkNumber = 1
	
			$contactListChunks | ForEach-Object {
				$joinedPaths = $_ -join ' '
				$chunkName = if ($contactListChunks.Count -eq 1) { $contactListName } else { "$($contactListName)_$($chunkNumber).part" }
	
				# Create and run montage command
				$cmd = "magick montage -label `"%f`" $joinedPaths -tile 6x -geometry 200x200+5+5> `"$($chunkName).jpg`""
				Invoke-Expression $cmd
				
				if ($contactListChunks.Count -gt 1) {
					Write-Log "$directoryPrefix Created contact sheet chunk: $chunkName"
				}
	
				$chunkNumber += 1
			}
	
			if ($contactListChunks.Count -gt 1) {
				$chunkFiles = Get-TempFiles | Sort-Object Name
				$chunkFilePaths = Extract-Rel-Paths . $chunkFiles
				$joinedPaths = $chunkFilePaths -join ' '
				
				# Create and run montage command
				$cmd = "magick montage $joinedPaths -tile 1x -geometry +0+0> `"$($contactListName).jpg`""
				Invoke-Expression $cmd
	
				Write-Log "$directoryPrefix Merged chunks"
			}
			
			# Remove each file
			Get-TempFiles | ForEach-Object {
				Remove-Item $_ -Force
				Write-Log "$directoryPrefix Removed: $_"
			}
	
			Write-Success "$directoryPrefix Created contact list"
			
			$contactListNumber += 1
		}

		if (Test-Path "./$directoryName.zip") {
			Write-Warning "$directoryPrefix Archive with the directory name already exists. Skipped the step"
		} else {
			Compress-Archive -Path "$path\*" -DestinationPath "$($path).zip" -Force
	
			Write-Success "$directoryPrefix Compressed directory"
		}

		$currentDir += 1
	}
}
