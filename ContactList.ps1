$chunkSize = 210

Get-ChildItem -Path . -Directory | ForEach-Object {
    $folder = $_.FullName
    $contactListNamePrefix = "$($_.Name)"
    $images = Get-ChildItem -LiteralPath "$folder" | Where-Object { $_.Extension.ToLower() -match '\.jpg|\.jpeg|\.png' } | Sort-Object Name

    if ($images.Count -eq 0) {
        Write-Host "⚠️ No images found in '$folder'"
		return
    }	
	
	# Build quoted list of file paths
	$imagePaths = $images | ForEach-Object {
		$absolutePath = $_.FullName
		$relativeUri = (New-Object System.Uri($folder)).MakeRelativeUri($absolutePath)
		$relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString()) -replace '/', '\'
		
		'"' + $relativePath + '"'
	}
	
	$imageChunks = @()
	for ($i = 0; $i -lt $imagePaths.Count; $i += $chunkSize) {
		$group = $imagePaths[$i..([math]::Min($i + $chunkSize - 1, $imagePaths.Count - 1))]
		$imageChunks += ,@($group)  # comma ensures each group is added as an array
	}

	$chunkNumber = 1
	
	# Now $imageChunks is an array of arrays
	$imageChunks | ForEach-Object {
		$joinedPaths = $_ -join ' '
		$contactListName = if ($imageChunks.Count -eq 1) { $contactListNamePrefix } else { "$($contactListNamePrefix)_$($chunkNumber)" }

		# Create and run montage command
		$cmd = "magick montage -label `"%f`" $joinedPaths -tile 6x -geometry 200x200+5+5> `"$($contactListName).jpg`""
		Invoke-Expression $cmd

		Write-Host "✅ Created contact sheet: $contactListName"
		
		$chunkNumber += 1
	}
	
	Compress-Archive -Path "$folder\*" -DestinationPath "$($folder).zip" -Force
	
	Write-Host "✅ Compressed directory: $folder"
}
