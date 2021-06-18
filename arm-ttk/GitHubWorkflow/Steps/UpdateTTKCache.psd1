@{
    name = "Update TTK Cache"
    uses = "Azure/powershell@v1"
    with = @{
        "inlineScript" = @'
Get-ChildItem -Recurse -Filter arm-ttk.psd1 | Import-Module -Name { $_.FullName} -Force -PassThru | Out-String
Update-TTKCache
'@
        "azPSVersion" = "3.1.0"
    }
}
<#
name: Azure PowerShell Action
        uses: Azure/powershell@v1
        with:
          inlineScript: Get-AzVM -ResourceGroupName "< YOUR RESOURCE GROUP >"
          azPSVersion: 3.1.0
#>
