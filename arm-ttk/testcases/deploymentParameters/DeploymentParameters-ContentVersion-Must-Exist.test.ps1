﻿<#
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
    continue
} 

if ($TemplateObject.contentVersion -isnot [string]) {
    Write-Error -ErrorId ContentVersion.Not.String -Message "contentVersion must be string" -TargetObject $TemplateObject.contentVersion 
    continue
} 

if ($TemplateObject.contentVersion -inotmatch '^(([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)$') {
    Write-Warning -Message "Recommended that the 'contentVersion' should be a version string 
    Like:  1.0.0.0  -> but found: $($TemplateObject.contentVersion)"
    continue
} 