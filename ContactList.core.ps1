function Get-SupportedImages {
    param (
		[string]$Path
	)

    return Get-ChildItem -LiteralPath "$Path" | Where-Object { $_.Extension.ToLower() -match '\.jpg|\.jpeg|\.png' }
}
