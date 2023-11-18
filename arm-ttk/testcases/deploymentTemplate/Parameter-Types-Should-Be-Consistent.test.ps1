<#
.SYNOPSIS
    Ensures Parameter Types are Consistent
.DESCRIPTION
    Ensures Parameter Types are Consistently the same within a deployment template and any inner templates
#>
param(
# The template object, with inline templates removed to keep the proper scope of tests when parsing - could be the mainTemplate.json or a nested template.
[PSObject]
$TemplateObject,

# The original mainTemplate.json object, without any modifications - nested templates are still inline ($TemplateObject has replaced any inner templates with blanks).
[PSObject]
$OriginalTemplateObject,

# The list of inner templates
[PSObject[]]
$InnerTemplates,

# If set, the current -TemplateObject is an inner template.
[switch]
$IsInnerTemplate
)


if ($IsInnerTemplate) { return }   # If we are evaluating an inner template, return (this test should run once per file)
if (-not $OriginalTemplateObject) { return} # If there was no original template object, then there is nothing to check.
# Find the list of original inner templates (using $OriginalTemplateObject)
$originalInnerTemplates = @(Find-JsonContent -InputObject $OriginalTemplateObject -Key template |
    Where-Object { $_.expressionEvaluationOptions.scope -eq 'inner' } |
    Sort-Object JSONPath -Descending)
    

# Walk over each inner template
foreach ($inner in $originalInnerTemplates) {
    # Then walk over each parameter passed to that template
    foreach ($innerTemplateParam in $inner.ParentObject[0].properties.parameters.psobject.properties) {
        $parameterName = $innerTemplateParam.Name
        
        $mappedParameterName = # Determine what external parameter this template parameter is mapped to.
            $innerTemplateParam.Value | 
            ?<ARM_Parameter> -Extract | 
            Select-Object -ExpandProperty ParameterName

        # Find the type of the inner template
        $innerTemplateParameterType = $inner.template.parameters.$parameterName.type

        foreach ($parent in $inner.ParentObject) { # Walk up the list of parent objects until
            if ($parent.parameters.$mappedParameterName.type -and  # We find this parameter defined
                $parent.parameters.$mappedParameterName.type -ne $innerTemplateParameterType # with a different type.    
            ) {
                $innerTemplateParamValue = $innerTemplateParam.Value
                $regexParam = "\[.*parameters(?<mappedParameterName>\(.*\))(\[.*?\]|\.|\,)(.*)\]" # https://regex101.com/r/V0dzVv/1 and https://regex101.com/r/ao6tsK/1 https://github.com/Azure/arm-ttk/issues/635
                if($null -ne $innerTemplateParamValue.value)
                {
                    $innerTemplateParamValue = $innerTemplateParamValue.value
                }
                if(($innerTemplateParamValue -is [string]) -and ($innerTemplateParamValue -notmatch $regexParam))
                {
                # If this is the case, write an error
                Write-Error -ErrorId Inconsistent.Parameter -Message "Type Mismatch: Parameter '$parameterName' in nested template '$($inner.ParentObject[0].name)' is defined as $innerTemplateParameterType, but the parent template defines it as $($parent.parameters.$mappedParameterName.type))." -TargetObject ([PSCustomObject]@{
                    JSONPath = $inner.JSONPath + ".parameters.$parameterName"
                })
                break # and then stop processing, because we only wish to compare this against the immediate parent template.
                }
            }
        }
    }
}