function Write-Log {
    param (
		[string]$Message
	)

    Write-Host "[LOG] $Message"
}

function Write-Success {
    param (
		[string]$Message
	)

    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param (
		[string]$Message
	)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param (
		[string]$Message
	)

    Write-Host "[ERR] $Message" -ForegroundColor Red
}

function Write-Section {
    param (
		[string]$Name
	)
    
    Write-Host ("=" * 50)
    Write-Host $Name -ForegroundColor Green
    Write-Host ("=" * 50)
}
