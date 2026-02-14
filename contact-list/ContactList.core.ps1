function Get-SupportedImages {
    param (
		[string]$Path
	)

    return Get-ChildItem -LiteralPath "$Path" | Where-Object { $_.Extension.ToLower() -match '\.jpg|\.jpeg|\.png' }
}

function Get-DirectoriesWithImages {
    return Get-ChildItem -Path . -Directory | Where-Object { (Get-SupportedImages $_.FullName).Count -gt 0 }
}

function Extract-RelativePaths {
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

function Get-TempFiles {
    return Get-ChildItem -LiteralPath . -Filter "*.part.jpg" -File
}
