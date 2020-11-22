<#
.Synopsis
    Ensures that the 'parameters' property exists in a template
.Description
    Ensures that an Azure Resource Manager template contains the 'parameters' property.
#>
param(
    # The template object
    [Parameter(Mandatory=$true,Position=0)]
    [PSObject]
    $TemplateObject
)

if (-not $TemplateObject.psobject.properties.item('parameters')) {
    Write-Error -ErrorId Parameters.Missing.Parameters -Message "Parameters property must exist in the parameters file" 
} 