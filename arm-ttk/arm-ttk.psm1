#region JSON Functions
#powershell 6+ provides support for json with comments
if ($PSVersionTable.PSVersion.Major -lt 6) {
    . $psScriptRoot\ConvertFrom-Json.ps1 # Overwriting ConvertFrom-JSON to allow for comments within JSON (not on core)
}

. $psScriptRoot\Import-Json.ps1
. $PSScriptRoot\Find-JsonContent.ps1
. $PSScriptRoot\Resolve-JSONContent.ps1

#endregion JSON Functions

#region Template Functions
. $PSScriptRoot\Expand-AzTemplate.ps1
. $PSScriptRoot\Test-AzTemplate.ps1
. $PSScriptRoot\Test-AzMarketplacePackage.ps1

. $PSScriptRoot\Format-AzTemplate.ps1
#endregion Template Functions

#region Cache Functions
. $psScriptRoot\Update-TTKCache.ps1
#endregion Cache Functions

# Set-Alias Format-AzTemplate Sort-AzTemplate

. $psScriptRoot\ttk.irregular.ps1

# check for a newer version
function ExtractVersion($s) {
    $a = @()
    $v = ""
    try{
        $v = ($s.Replace("@{", "").Replace("}", "") | ConvertFrom-StringData).ModuleVersion
    } catch {}
    $a = $v.Split('.')
    if ($a.length -gt 1) {
        $major = [int]$a[0]
        $minor = [int]$a[1]
        return @{"major" = $major; "minor" = $minor }
    }
    else {
        return @{"major" = 0; "minor" = 0 }
    }
}

$latestUri = "https://aka.ms/arm-ttk-version"

try {
    $r = (Invoke-WebRequest $latestUri).Content
} catch {}

$latestVersion = ExtractVersion $r

$psd = Get-Content -path "$psScriptRoot\arm-ttk.psd1" -raw
$installedVersion = ExtractVersion $psd 

if ($installedVersion.major -lt $latestVersion.major -or 
($installedVersion.minor -lt $latestVersion.minor -and $installedVersion.major -eq $latestVersion.major)) {
    Write-Host "A newer version of the ARM-TTK is available at: https://github.com/Azure/arm-ttk/releases" -ForegroundColor yellow
    Write-Host "Installed Version: $($installedVersion.major).$($installedVersion.minor)" -ForegroundColor yellow
    Write-Host "Latest Version: $($latestVersion.major).$($latestVersion.minor)" -ForegroundColor yellow
}
