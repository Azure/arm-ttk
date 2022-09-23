<#
.Synopsis
    Ensure that parameters that don't have defaultValues are defined CreateUIDefinition.outputs
.Description
    Ensure that parameters that don't have defaultValues are defined CreateUIDefinition.outputs
#>

param(
[Parameter(Mandatory=$true)]
[PSObject]
$TemplateObject,

[Parameter(Mandatory=$true)]
[PSObject]
$CreateUIDefinitionObject,

# If set, the TemplateObject is an inner template.
[switch]
$IsInnerTemplate
)

# We do not need to consider if inner template parameters exist in CreateUIDefinition.
if ($IsInnerTemplate) { return }

foreach ($parameter in $TemplateObject.parameters.psobject.properties) {
    $parameterName = $parameter.Name
    $parameterInfo = $parameter.Value
    $defaultValue = $parameterInfo.defaultValue
    if ($defaultValue -eq $null) { # empty string is ok, only missing defaultValues should be flagged
        if ($CreateUIDefinitionObject.parameters.outputs.$parameterName -eq $null) {
            Write-Error "$parameterName does not have a default value, and is not defined in CreateUIDefinition.outputs" -ErrorId Parameter.Without.Default.Missing.From.CreateUIDefinition -TargetObject $TemplateObject.parameters
            continue
        }
    }
}
