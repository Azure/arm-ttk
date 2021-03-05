<#
.Synopsis
    Ensures the apiVersions in reference functions are recent.
.Description
    Ensures the apiVersions of any reference functions are are recent and non-preview.
.Example
    Test-AzTemplate -TemplatePath .\100-marketplace-sample\ -Test apiVersions-Should-Be-Recent
.Example
    .\apiVersions-References-Should-Be-Recent.test.ps1 -TemplateObject (
        Get-Content ..\..\..\..\100-marketplace-sample\azureDeploy.json -Raw | ConvertFrom-Json
    ) -TemplateText (
        Get-Content ..\..\..\..\100-marketplace-sample\azureDeploy.json -Raw
    ) -AllAzureResources (
        Get-Content ..\..\cache\AllAzureResources.cache.json | ConvertFrom-Json
    )
      -TestDate (
          [datetime]::ParseExact("31/08/2019", "dd-mm-yy", $null)
    )
#>
param(
    # The template object
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    # The text of the template
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateText,

    # All potential resources in Azure (from cache)
    [Parameter(Mandatory = $true, Position = 2)]
    [PSObject]
    $AllAzureResources,

    # Number of days that the apiVersion must be less than
    [Parameter(Mandatory = $false, Position = 3)]
    [int32]
    $NumberOfDays = 730,

    # Test Run Date - date to use when doing comparisons, if not current date (used for unit testing against and old cache)
    [Parameter(Mandatory = $false, Position = 3)]
    [datetime]
    $TestDate = [DateTime]::Now

)


if (-not $TemplateObject.resources) {
    # If we don't have any resources
    # then it's probably a partial template, and there's no apiVersions to check anyway, 
    return # so return.
}

$listFunctions = $TemplateText | ?<ARM_List_Function>
$referenceFunctions = $TemplateText | ?<ARM_Template_Function> -FunctionName reference

foreach ($ref in $referenceFunctions) {
    $refApiVersion = $ref | ?<ARM_API_Version>
    if (-not $refApiVersion) { continue }
    $ref.Groups["Parameters"]

}
