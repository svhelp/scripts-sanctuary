. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\ContactList.core.ps1"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Create-ContactLists {
	param (
		[int]$ContactListSize,
		[int]$ChunkSize,
		[switch]$OneImagePerLevel
	)

	Write-Section "Creating Contact Lists"
	
    $currentDirectory = (Get-Location).Path
 
    if (-not $currentDirectory.EndsWith('\')) {
        $currentDirectory = $currentDirectory + '\'
    }

	$directoriesWithImages = if ($OneImagePerLevel.IsPresent)
		{
			Get-ChildItem -Path . -Directory
		} else {
			Get-DirectoriesWithImages
		}

	$totalDirs = $directoriesWithImages.Count
	$currentDir = 1

	$directoriesWithImages | ForEach-Object {
        $directoryShortPrefix = "[$currentDir/$totalDirs]"
        $directoryPrefix = "$directoryShortPrefix `"$_`""
        $path = $_.FullName
        $directoryName = $_.Name
		$contactListNamePrefix = "$($_.Name)"

		Write-Log "$directoryPrefix Started processing..."

		if ($OneImagePerLevel.IsPresent) {
				$dirs = Get-ChildItem -Path $path -Recurse -Directory
				$selectedImages = @()
				foreach ($dir in $dirs + (Get-Item $path)) {
						$img = Get-ChildItem -Path $dir.FullName -File | Where-Object { $_.Extension.ToLower() -match '\.jpg|\.jpeg|\.png' } | Select-Object -First 1
						if ($img) { $selectedImages += $img }
				}
				$imagePaths = @(Extract-RelativePaths $path $selectedImages)
		} else {
				$images = Get-SupportedImages "$path" | Sort-Object Name
				$imagePaths = @(Extract-RelativePaths $path $images)
		}

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
					Write-Log "$directoryShortPrefix Created contact sheet chunk: $chunkName"
				}
	
				$chunkNumber += 1
			}
	
			if ($contactListChunks.Count -gt 1) {
				$chunkFiles = Get-TempFiles | Sort-Object Name
				$chunkFilePaths = Extract-RelativePaths $currentDirectory $chunkFiles
				$joinedPaths = $chunkFilePaths -join ' '

				# Create and run montage command
				$cmd = "magick montage $joinedPaths -tile 1x -geometry +0+0> `"$($contactListName).jpg`""
				Invoke-Expression $cmd
	
				Write-Log "$directoryShortPrefix Merged chunks"
			}
			
			# Remove each file
			Get-TempFiles | ForEach-Object {
				Remove-Item -LiteralPath $_.FullName -Force
				Write-Log "$directoryShortPrefix Removed: $_"
			}
	
			Write-Success "$directoryPrefix Created contact sheet ($contactListNumber)"
			
			$contactListNumber += 1
		}

		if (Test-Path -LiteralPath "./$directoryName.zip") {
			Write-Warning "$directoryPrefix Archive with the directory name already exists. Skipped the step"
		} else {
			# CompressionLevel: Optimal / Fastest / NoCompression
			[System.IO.Compression.CompressionLevel]$level = [System.IO.Compression.CompressionLevel]::Fastest

			# includeBaseDirectory = $false -> в архив попадёт только содержимое папки
			[System.IO.Compression.ZipFile]::CreateFromDirectory($path, "$($path).zip", $level, $false)
	
			Write-Success "$directoryPrefix Compressed directory"
		}

		$currentDir += 1
	}
}
