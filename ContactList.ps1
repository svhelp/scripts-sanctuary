. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\ContactList.core.ps1"
. "$PSScriptRoot\ContactList.process.ps1"
. "$PSScriptRoot\ContactList.verification.ps1"

$chunkSize = 60
$contactListSize = 210

Create-ContactLists $contactListSize $chunkSize
Verify-Contactlists $contactListSize
