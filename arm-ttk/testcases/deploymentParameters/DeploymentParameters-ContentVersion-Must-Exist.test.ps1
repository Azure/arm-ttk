<#
.Synopsis
    Ensures that the 'contentVersion' property exists in a template
.Description
    Ensures that an Azure Resource Manager template contains the 'contentVersion' property.
    And that is formatted like a proper version, ie 1.0.0.0
#>
param(
    # The template object
    [Parameter(Mandatory=$true,Position=0)]
    [PSObject]
    $TemplateObject
)

if (-not $TemplateObject.psobject.properties.item('contentVersion')) {
    Write-Error -ErrorId Parameters.Missing.ContentVersion -Message "contentVersion property must exist in the template"
    return;
} 

if ($TemplateObject.contentVersion -isnot [string]) {
    Write-Error -ErrorId ContentVersion.Not.String -Message "contentVersion must be string" -TargetObject $TemplateObject.contentVersion 
    return;
} 

if ($TemplateObject.contentVersion -notmatch '\d{1,3}\.\d{1,3}\.\d{1,5}\.\d{1,5}') {
    Write-Error -ErrorId ContentVersion.Bad.Format -TargetObject $TemplateObject.contentVersion  -Message "contentVersion must be a version string 
    Like:  1.0.0.0  -> but found: $($TemplateObject.contentVersion)"
    return;
} 