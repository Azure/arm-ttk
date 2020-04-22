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

# TODO: do we still need this test?  it's implied by checking for other parameters (e.g. location)
if (-not $TemplateObject.psobject.properties.item('parameters')) {
    Write-Error -Message "Parameters property must exist in the template" -ErrorId 'Template.Missing.Parameters'
} 