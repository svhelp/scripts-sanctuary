  param (
    [switch]$OneImagePerLevel
  )
  
. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\ContactList.core.ps1"
. "$PSScriptRoot\ContactList.process.ps1"
. "$PSScriptRoot\ContactList.verification.ps1"

  $chunkSize = 30
  $contactListSize = 210

  Create-ContactLists -ContactListSize $contactListSize -ChunkSize $chunkSize -OneImagePerLevel:$OneImagePerLevel
  Verify-Contactlists -ContactListSize $contactListSize -OneImagePerLevel:$OneImagePerLevel
