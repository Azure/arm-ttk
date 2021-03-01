<#
.Synopsis
    Ensures that the 'parameters' property exists in a template
.Description
    Ensures that an Azure Resource Manager template contains the 'parameters' property.
#>
param(
    # The parameter object
    [Parameter(Mandatory=$true,Position=0)]
    [PSObject]
    $ParameterObject
)

if (-not $ParameterObject.parameters) {
    Write-Error -ErrorId Parameters.Missing.Parameters -Message "Parameters property must exist in the parameters file" 
} 