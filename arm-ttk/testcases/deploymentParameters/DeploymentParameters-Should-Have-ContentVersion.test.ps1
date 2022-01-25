<#
.Synopsis
    Ensures that the 'contentVersion' property exists in a template
.Description
    Ensures that an Azure Resource Manager template contains the 'contentVersion' property.
    And that is formatted like a proper version, ie 1.0.0.0
#>
param(
  # The parameter object
  [Parameter(Mandatory=$true,Position=0)]
  [PSObject]
  $ParameterObject
)

$MarketplaceWarning = $false

if (-not $ParameterObject.contentVersion) {
    # Skippig error is schema is missing, i.e. '$schemaless'
    if ($ParameterObject.'$schema') { 
        Write-TtkMessage -MarketplaceWarning $MarketplaceWarning -ErrorId Parameters.Missing.ContentVersion -Message "contentVersion property must exist in the template"
    }
    return
} 

if ($ParameterObject.contentVersion -isnot [string]) {
    Write-TtkMessage -MarketplaceWarning $MarketplaceWarning -ErrorId ContentVersion.Not.String -Message "contentVersion must be string" -TargetObject $TemplateObject.contentVersion 
    return
} 

if ($ParameterObject.contentVersion -notmatch '^(\d+\.\d+\.\d+\.\d+)$') {
    Write-Warning -Message "Recommended that the 'contentVersion' should be a version string 
    Like:  1.0.0.0  -> but found: $($TemplateObject.contentVersion)"
    return
} 