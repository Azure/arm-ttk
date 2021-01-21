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
    Write-Error 'DeploymentTemplate Missing .$schema property' -ErrorId Template.Missing.Schema
    return
}

$validSchemas =
    'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#',  # See warning below, phasing this one out
    'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#',
    'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#',
    'https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#',
    'https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#'


if ($validSchemas -notcontains $templateSchema) {
    Write-Error "DeploymentTemplate has an unexpected Schema.
It should be one of the following:
$($validSchemas -join ([Environment]::NewLine))
" -ErrorId Template.Bad.Schema
    return
}

# after the grace period this should be removed and the schema removed from the $validSchemas array above
if ($templateSchema -eq 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'){
    Write-Warning "Template is using schema version '2015-01-01' which has been deprecated and is no longer maintained."
}
