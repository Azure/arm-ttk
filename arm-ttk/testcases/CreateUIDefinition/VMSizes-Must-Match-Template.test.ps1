<#
.Synopsis
    Ensure that VMSizes must match the template values
.Description
    Ensure that VMSizes must match the template values in SizeSelector
#>

param(
# The CreateUIDefinition object data
[Parameter(Mandatory=$true)]
[PSObject]
$CreateUIDefinitionObject,

# The parameters section of the main template file
[Parameter(Mandatory=$true)]
[Collections.IDictionary]
$MainTemplateParameters
)

# test is broken so turning it off for now...
#Write-Warning "Skipping Test..."
#break

# First, find all size selectors in CreateUIDefinition.
$sizeSelectors = $CreateUIDefinitionObject | 
    Find-JsonContent -Key type -Value Microsoft.Compute.SizeSelector


foreach ($selector in $sizeSelectors) { # Then walk each selector,
    # and attempt to find it in the main template
    $controlName = $selector.Name
    $stepsIndex = $selector.JSONPath.IndexOf('steps[', [StringComparison]::OrdinalIgnoreCase)


    $lookingFor= 
        if ($stepsIndex -ge 0) {
            $selectorJsonPath = $selector.JsonPath -replace '^\[\d+\]\.'
            $stepPath = $selectorJsonPath.Substring(0, $selector.JSONPath.IndexOf([char]']', $stepsIndex) + 1)            
            $theStep = & ([ScriptBlock]::Create("`$CreateUIDefinitionObject.$stepPath"))
            $stepName = $theStep.name
            "*steps(*$stepName*)*.$controlName*"
        } else {
            "*basics(*$($controlName)*"
        } 
    $theOutput = foreach ($out in $CreateUIDefinitionObject.parameters.outputs.psobject.properties) {
        if ($out.Value -like $lookingFor) { 
            $out; break
        }
    }

    if (-not $theOutput) {
        Write-Error "Could not find VM SizeSelector '$($selector.Name)' in outputs" -TargetObject $selector
        continue
    }

    $MainTemplateParam = $MainTemplateParameters[$theOutput.Name] # and find it in the main template.

    # If we couldn't, error out.
    if (-not $MainTemplateParam) {
        Write-Error "Output '$($theOutput.Name)' is missing from main template parameters "-TargetObject $theOutput
        continue
    }

    # Now check that if the main template has a DefaultValue, it's allowed in CreateUIDefintion.
    if ($MainTemplateParam.defaultValue) {
        if ($selector.constraints.allowedsizes -and # This is true if they have an allowed sizes
            $selector.constraints.allowedsizes -notcontains $MainTemplateParam.defaultValue # and they do not contain the default value.
        ) {
            # If that's the case, write an error.
            Write-Error "VM Size selector '$($selector.Name)' does not allow for the default value $($MainTemplateParam.defaultValue) used in the main template" 
        }
    }
}
