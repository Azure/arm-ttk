<#
.SYNOPSIS
    Ensures Parameter Types are Consistent
.DESCRIPTION
    Ensures Parameter Types are Consistently the same within a deployment template and any inner templates
#>
param(
# The template object
[PSObject]
$TemplateObject,

# The list of inner templates
[PSObject[]]
$InnerTemplates,

# If set, the current -TemplateObject is an inner template.
[switch]
$IsInnerTemplate
)


if ($IsInnerTemplate) { return } # If we are in an inner template, return.

foreach ($prop in $TemplateObject.parameters.PSObject.properties) {  # Walk over all parameters in the parameterName
    $parameterName = $prop.Name
    $parameterType = $prop.Value.Type
    foreach ($inner in $innerTemplates) { # then walk over each template
        if ($inner.template.parameters.($prop.Name).type -ne $parameterType) {  # If the parameter type differs
            # write an error.
            Write-Error -ErrorId Inconsistent.Parameter -Message "Parameter '$parameterName' is inconsistently used in inner template '$($inner.ParentObject[0].name)'" -TargetObject ([PSCustomObject]@{
                JSONPath = "parameters.$parameterName"
            })
        }
    }
}