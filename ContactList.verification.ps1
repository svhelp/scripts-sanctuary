. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\ContactList.core.ps1"

$zipSizeDeviationThreshold = 5

function Verify-Contactlists {
	param (
		[int]$ContactListSize,
		[switch]$OneImagePerLevel
	)

    Write-Section "Verification"
    
	$directoriesWithImages = if ($OneImagePerLevel.IsPresent)
		{
			Get-ChildItem -Path . -Directory
		} else {
			Get-DirectoriesWithImages
		}
        
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

        if (Test-Path -LiteralPath $expectedArchivePath) {
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
            
            if (!(Test-Path -LiteralPath $expectedContactListName)) {
                $success = $false
                Write-Error "$directoryPrefix lacks contact lists"

                break
            }
        }

        if ($success) {
            Write-Success "$directoryPrefix successfully processed"
        }

        $currentDir += 1
    }

    if ((Get-TempFiles).Count -gt 0) {
        Write-Error "Temp files left in the directory"
    }
}
