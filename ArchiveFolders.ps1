$currentDirectory = (Get-Location).Path

Get-ChildItem -Path $currentDirectory -Directory | ForEach-Object {
    $folder = $_
    $zipName = "$($folder.Name).zip"

	$compress = @{
		LiteralPath = Get-ChildItem -LiteralPath $folder.FullName | ForEach-Object { $_.FullName }
		CompressionLevel = "Fastest"
		DestinationPath = $zipName
	}

	Compress-Archive @compress

    Write-Host "Архив создан: $zipName"
}