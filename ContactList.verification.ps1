. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\ContactList.core.ps1"

$zipSizeDeviationThreshold = 5

function Verify-Contactlists {
	param (
		[int]$ContactListSize
	)

    Write-Section "Verification"

    $directoriesWithImages = Get-ChildItem -Path . -Directory | Where-Object { (Get-SupportedImages $_.FullName).Count -gt 0 }

    $totalDirs = $directoriesWithImages.Count
    $currentDir = 1

    $directoriesWithImages | ForEach-Object {
        $success = $true
        $directoryPrefix = "[$currentDir/$totalDirs] `"$_`""
        $path = $_.FullName
        $innerDirs = Get-ChildItem -LiteralPath "$path" -Directory

        if ($innerDirs.Count -gt 0) {
            Write-Warning "$directoryPrefix contains sub-directories"
        }

        $expectedArchivePath = ".\$_.zip"

        if (Test-Path $expectedArchivePath) {
            $archiveSize = (Get-Item -LiteralPath $expectedArchivePath).Length
            $dirSize = (Get-ChildItem -LiteralPath "$path" -Recurse -File | Measure-Object -Property Length -Sum).Sum
            $sizeDeviation = ($dirSize - $archiveSize) / $dirSize * 100

            if ($sizeDeviation -gt $zipSizeDeviationThreshold) {
                $roundedArchiveSize = [Math]::Round($archiveSize / 1KB, 2)
                $roundedDirectorySize = [Math]::Round($dirSize / 1KB, 2)

                Write-Warning "$directoryPrefix Archive size inconsistency: $roundedArchiveSize KB ($roundedDirectorySize KB initial size)"
            }
        } else {
            $success = $false
            Write-Error "$directoryPrefix hasn't been compressed"
        }

        $imagesCount = (Get-SupportedImages $path).Count
        $expectedContactListsCount = $imagesCount / $ContactListSize

        for ($i = 0; $i -lt $expectedContactListsCount; $i += 1) {
            $expectedContactListName = if ($expectedContactListsCount -gt 1) { ".\$($_)_$($i + 1).jpg" } else { ".\$_.jpg" }
            
            if (!(Test-Path $expectedContactListName)) {
                $success = $false
                Write-Error "$directoryPrefix lacks contact lists"

                break
            }
        }

        if ($success) {
            Write-Success "$directoryPrefix successgully processed"
        }

        $currentDir += 1
    }

    $tempFiles = Get-ChildItem -LiteralPath . | Where-Object { $_.Extension.ToLower() -match '\.part' }

    if ($tempFiles.Count -gt 0) {
        Write-Error "Temp files left in the directory"
    }
}
