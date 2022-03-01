<#
.Synopsis
    Ensures that .outputs are present in the .parameters of CreateUIDefinition.json
.Description
    Ensures that .outputs are present in the .parameters of CreateUIDefinition.json, and that those parameters exist on the template object
.Example
    Test-AzTemplate .\100-marketplace-sample -Test Outputs-Must-Be-Present-In-Template-Parameters
.Example
    .\Outputs-Must-Be-Present-In-Template-Parameters.test.ps1 -CreateUIDefinitionObject @([PSCustomObject]@{badinput=$true}) -TemplateObject ([PSCustomObject]@{})
.Notes
    This also attempts to validate the return type of an output, provided that the return type is not a string.

    It currently _does not_ attempt to validate the data type of the control, 
    and thus may give a false positive in the case of Checkboxes and other non-string CreateUiDefinition controls.

    The list of acceptable output functions by datatype is accessible in the parameter -AllowedFunctionInOutput.
    
    It currently only checks integer and boolean types.  If you believe an additional exception is needed, please file an issue on GitHub.
#>
param(
# The CreateUIDefinition Object (the contents of CreateUIDefinition.json, converted from JSON)
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$CreateUIDefinitionObject,

# The Template Object (the contents of azureDeploy.json, converted from JSON)
[Parameter(Mandatory=$true,Position=1)]
[PSObject]
$TemplateObject,

# If set, the TemplateObject is an inner template.
[switch]
$IsInnerTemplate,

# The allowed functions for a given data type.
# This is not accounting for the type or control.
[Collections.IDictionary]
$AllowedFunctionInOutput = $(@{
    int = 'int', 'min', 'max', 'div', 'add', 'mod', 'mul', 'sub', 'copyIndex','length', 'coalesce'
    bool = 'equals', 'less', 'lessOrEquals', 'greater', 'greaterOrEquals', 'and', 'or','not', 'true', 'false', 'contains','empty','coalesce','if'
})
)

# If the TemplateObject is inner template of MainTemplate, skip the test
if ($IsInnerTemplate) {
    return
}



# First, make sure CreateUIDefinition has outputs
if (-not $CreateUIDefinitionObject.parameters.outputs) {
    Write-Error "CreateUIDefinition is missing the .parameters.outputs property" -ErrorId CreateUIDefinition.Missing.Outputs     # ( write an error if it doesn't)
}

$parameterInfo = $CreateUIDefinitionObject.parameters

foreach ($output in $parameterInfo.outputs.psobject.properties) { # Then walk thru each output
    $outputName = $output.Name
    if ($outputName -eq 'applicationresourcename' -or `
        $outputName -eq 'jitaccesspolicy' -or `
        $outputName -eq 'managedidentity' -or `
        $outputName -eq 'managedresourcegroupid') { # If the output was one of the outputs used for Managed Apps and only found in the generated template, skip the test
            continue 
    }

    
    
    # If the output name was not declared in the TemplateObject
    if (-not $TemplateObject.parameters.$outputName) {
        # write an error
        Write-Error "output $outputName does not exist in template.parameters" -ErrorId CreateUIDefinition.Output.Missing.From.MainTemplate -TargetObject $parameterInfo.outputs
    }
    
    $outputParameterType = $TemplateObject.parameters.$outputName.type
    if ($outputParameterType -and $outputParameterType -ne 'string') {
        $firstOutputFunction = $output.Value | ?<ARM_Template_Function> -Extract | Select-Object -ExpandProperty FunctionName
        if ($AllowedFunctionInOutput) {
            foreach ($af in $AllowedFunctionInOutput.GetEnumerator()) {
                if ($outputParameterType -eq $af.Key -and $firstOutputFunction -notin $af.Value) {
                    Write-Warning "output $outputName does not return the expected type '$outputParameterType'" -ErrorId CreateUIDefinition.Output.Incorrect -TargetObject $parameterInfo.outputs
                }
            }
        }       
    }
}
