#region JSON Functions
if ($PSVersionTable.PSEdition -ne 'Core') {
    . $psScriptRoot\ConvertFrom-Json.ps1 # Overwriting ConvertFrom-JSON to allow for comments within JSON (not on core)
}

. $psScriptRoot\Import-Json.ps1
. $PSScriptRoot\Find-JsonContent.ps1
. $PSScriptRoot\Resolve-JSONContent.ps1

#endregion JSON Functions

#region Template Functions
. $PSScriptRoot\Expand-AzTemplate.ps1
. $PSScriptRoot\Test-AzTemplate.ps1

. $PSScriptRoot\Format-AzTemplate.ps1
#endregion Template Functions

#region Cache Functions
. $psScriptRoot\Update-TTKCache.ps1
#endregion Cache Functions

# Set-Alias Format-AzTemplate Sort-AzTemplate

. $psScriptRoot\ttk.irregular.ps1