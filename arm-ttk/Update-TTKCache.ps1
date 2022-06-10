function Update-TTKCache {
    <#
    .Synopsis
        Updates the TTK Cache
    .Description
        Updates the /cache/ information in the Azure Resource Manager Template Toolkit
    .Example
        Update-TTKCache
    #>
    param()

    $MyInvocation.MyCommand.ScriptBlock.File | 
    Split-Path | 
    Join-Path -ChildPath cache |
    Get-ChildItem -Filter *.init.cache.ps1 |
    ForEach-Object {
        & $_.Fullname
    }
}

function Compare-TTKVersion {

    $psdUri = "https://aka.ms/arm-ttk-version"

    $r = (Invoke-WebRequest $psdUri).Content
    $r = $r.Replace("@{", "").Replace("}", "")
    $r = $r | ConvertFrom-StringData

    $latestVersion = $r.ModuleVersion

    $a = $latestVersion.Split('.')
    $major = [int]$a[0]
    $minor = [int]$a[1]

    $currentVersion = (get-module 'arm-ttk').Version

    if ($currentVersion.Major -lt $major -or 
   ($currentVersion.Minor -lt $minor -and $currentVersion.Major -eq $major)) {
        Write-Host "A newer version of the ARM-TTK is available at: https://github.com/Azure/arm-ttk/releases" -ForegroundColor yellow
        Write-Host "Current Version: $currentVersion" -ForegroundColor yellow
        Write-Host "Latest Version: $latestVersion" -ForegroundColor yellow
    }

}