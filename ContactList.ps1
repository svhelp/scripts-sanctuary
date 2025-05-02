$OutputEncoding = [System.Text.Encoding]::UTF8

$chunkSize = 60
$contactListSize = 210

$currentDirectory = (Get-Location).Path

if (-not $currentDirectory.EndsWith('\')) {
    $currentDirectory = $currentDirectory + '\'
}

# Build quoted list of file paths
function Extract-Rel-Paths {
	param (
		[string]$Root,
		[System.Object]$Files
	)

	return $Files | ForEach-Object {
		$absolutePath = $_.FullName
		$relativeUri = (New-Object System.Uri($Root)).MakeRelativeUri($absolutePath)
		$relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString()) -replace '/', '\'
		
		'"' + $relativePath + '"'
	}
}

Get-ChildItem -Path . -Directory | ForEach-Object {
    $folder = $_.FullName
    $contactListNamePrefix = "$($_.Name)"
    $images = Get-ChildItem -LiteralPath "$folder" | Where-Object { $_.Extension.ToLower() -match '\.jpg|\.jpeg|\.png' } | Sort-Object Name

    if ($images.Count -eq 0) {
        Write-Host "⚠️ No images found in '$folder'"
		return
    }	
	
	$imagePaths = Extract-Rel-Paths $folder $images
	
	$contactLists = @()

	for ($i = 0; $i -lt $imagePaths.Count; $i += $contactListSize) {
		$group = $imagePaths[$i..([math]::Min($i + $contactListSize - 1, $imagePaths.Count - 1))]
		$contactLists += ,@($group)  # comma ensures each group is added as an array
	}

	$contactListNumber = 1
	
	# Now $contactLists is an array of arrays
	$contactLists | ForEach-Object {
		$contactListName = if ($contactLists.Count -eq 1) { $contactListNamePrefix } else { "$($contactListNamePrefix)_$($contactListNumber)" }

		$contactListChunks = @()

		for ($i = 0; $i -lt $_.Count; $i += $chunkSize) {
			$chunk = $_[$i..([math]::Min($i + $chunkSize - 1, $_.Count - 1))]
			$contactListChunks += ,@($chunk)  # comma ensures each group is added as an array
		}
		
		$chunkNumber = 1

		$contactListChunks | ForEach-Object {
			$joinedPaths = $_ -join ' '
			$chunkName = if ($contactListChunks.Count -eq 1) { $contactListName } else { "$($contactListName)_$($chunkNumber).part" }

			# Create and run montage command
			$cmd = "magick montage -label `"%f`" $joinedPaths -tile 6x -geometry 200x200+5+5> `"$($chunkName).jpg`""
			Invoke-Expression $cmd
			
			Write-Host "✅ Created contact sheet chunk: $chunkName"

			$chunkNumber += 1
		}

		if ($contactListChunks.Count -gt 1) {
			$chunkFiles = Get-ChildItem -LiteralPath "$currentDirectory" | Where-Object { $_.Name -like "*.part.jpg" } | Sort-Object Name
			$chunkFilePaths = Extract-Rel-Paths $currentDirectory $chunkFiles
			$joinedPaths = $chunkFilePaths -join ' '
			
			# Create and run montage command
			$cmd = "magick montage $joinedPaths -tile 1x -geometry +0+0> `"$($contactListName).jpg`""
			Invoke-Expression $cmd

			Write-Host "✅ Joined chunks"

			# Remove each file
			$chunkFiles | ForEach-Object {
				if (Test-Path $_) {
					Remove-Item $_ -Force
					Write-Host "🗑️ Removed: $_"
				} else {
					Write-Host "⚠️ File not found: $_"
				}
			}
		}

		Write-Host "✅ Created contact sheet: $contactListName"
		
		$contactListNumber += 1
	}
	
	Compress-Archive -Path "$folder\*" -DestinationPath "$($folder).zip" -Force
	
	Write-Host "✅ Compressed directory: $folder"
}
