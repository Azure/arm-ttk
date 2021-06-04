<#
.Synopsis
    Determines that the DeploymentTemplate schema is correct
.Description
    Determines that the .$schema property of any DeploymentTemplate is correct
#>
param(
    # The parameter object
    [PSObject]
    $ParameterObject
)

$templateSchema = $ParameterObject.'$schema'

if (-not $templateSchema) {
    # Skippig error is content version is missing, i.e. '$schemaless'
    if ($ParameterObject.contentVersion ) { 
        Write-Error -ErrorId Parameters.Missing.Schema -Message 'DeploymentParameters Missing .$schema property' 
    }
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
