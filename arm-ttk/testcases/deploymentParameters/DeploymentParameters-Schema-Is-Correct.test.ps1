<#
.Synopsis
    Determines that the DeploymentTemplate schema is correct
.Description
    Determines that the .$schema property of any DeploymentTemplate is correct
#>
param(
[PSObject]$TemplateObject
)

$templateSchema = $TemplateObject.'$schema'

if (-not $templateSchema) {
    Write-Error 'DeploymentParameters Missing .$schema property' -ErrorId Parameters.Missing.Schema
    return
}

$validSchemas = 
    'https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#',
    'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'

if ($validSchemas -notcontains $templateSchema) {
    Write-Error  -ErrorId Parameters.Bad.Schema -Message "DeploymentParameters has an unexpected Schema.
    Found: $templateSchema
It should be one of the following:
$($validSchemas -join ([Environment]::NewLine))"
    return   
}
