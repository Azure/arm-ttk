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
