<#
.Synopsis
    Ensures allowed values in CreateUIDefinition are allowed in MainTemplate
.Description
    Ensures the values in each CreateUIDefinition control are allowed in the corresponding MainTemplate parameter.
#>
param(
[Parameter(Mandatory=$true)]
[PSObject]
$CreateUIDefinitionObject,

[Parameter(Mandatory=$true)]
[string]
$CreateUIDefinitionText,

[Parameter(Mandatory=$true)]
[Collections.IDictionary]
$MainTemplateParameters
)

$progressId = [Random]::new().Next()
$count = 0 

Write-Progress -Id $progressId "Finding Controls" " " 

# Find any item property in CreateUIDefinition that uses allowedValues
$allowedValues = @($CreateUIDefinitionObject | 
    Find-JsonContent -Key allowedValues -Value * -Like)

foreach ($av in $allowedValues) { # Walk thru each thing we find.
    
    # First we need to find the control's associated output.
    $parent = $av.ParentObject[0] 
    $controlName = $parent.Name
    if ($controlName) {
        $count++
        $p = $count * 100/ $allowedValues.Count
        Write-Progress -Id $progressId "Checking Controls $($controlName)" " " -PercentComplete $p
        $stepName = $av.ParentObject[1].name # If the grandparent object has a name field, we're in steps
        $lookingFor= @{controlName=$controlName}
        if ($stepName) { $lookingFor.StepName = $stepName }
        $theOutput = foreach ($out in $CreateUIDefinitionObject.parameters.outputs.psobject.properties) {
            if ($out.Value | ?<CreateUIDefinition_Output> @lookingFor) {
                $out; break
            }
        }
    } elseif ($av.JSONPath -like '*.config.*') {
        $configName = @($av.JSONPath -split '\.')[-2]
        $theOutput = foreach ($out in $CreateUIDefinitionObject.parameters.outputs.psobject.properties) {
            if ($out.Value -like "*$configName(*") {
                $out; break
            }
        }
    }

    # If we couldn't find the matching output
    if (-not $theOutput) {
        if ($CreateUIDefinitionText -notmatch "\.$($parent.Name)") { # and the control is not referred to elsewhere
            # write an error.
            Write-Error "Could not find $($parent.Name) in outputs" -TargetObject $parent
        }
        # Regardless, if we couldn't find the step in outputs, we move onto the next control with allowed values.
        continue 
    }


    $MainTemplateParam = $MainTemplateParameters[$theOutput.Name]

    # If it didn't exist in the mainTemplate
    if (-not $MainTemplateParam) {
        # write an error and move onto the next item
        Write-Error "CreateUIDefinition has parameter $($parent.Name), but it is missing from main template parameters "-TargetObject $parent
        continue
    }

    # Now create a list of all allowed values
    $reallyAllowedValues = @(foreach ($v in $av.allowedValues) {
        if ($v.psobject.properties.Item('Value')) { # they can either be in a 'value' property
            $v.value
        } else { # or just there as a string
            $v
        }
    })

    

    $paramName = if ($parent.name) { $parent.name } elseif ($configName) { $configName }

    if ($MainTemplateParam.allowedValues) { # If the main template parameter has allowed values
        
        :CheckNextValue # then we want to check each value in order to see if it's permitted.
            foreach ($rv in $reallyAllowedValues) {
                foreach ($v in $MainTemplateParam.allowedValues) {
                    if ($v -like "*$rv*") { continue CheckNextValue }
                }
                Write-Error "CreateUIDefinition parameter '$paramName' with value $rv is not allowed in the main template parameter $($theOutput.Name)" -ErrorId Allowed.Value.Mismatch
            }
    } 

    
    if ($MainTemplateParam.defaultValue -and # If the main template has a default value
        $MainTemplateParam.defaultValue -replace '\s' -ne '[resourceGroup().location]') { # and it's not [resourceGroup().location] 

        # Walk thru each potential value in the main template parameter.
        foreach ($mainTemplateDefault in $MainTemplateParam.defaultValue) {
            # skip each individual value that is really allowed.
            if ($reallyAllowedValues -contains $mainTemplateDefault) { continue }
        
        
            $foundDefaultValue = $false
            :CheckNextValue # then we want to check each value in order to see if it's permitted.
                foreach ($rv in $reallyAllowedValues) {
                    foreach ($v in $MainTemplateParam.allowedValues) {
                        if ($v -like "*$($MainTemplateParam.defaultValue)*") { 
                            $foundDefaultValue = $true
                            break CheckNextValue 
                        }
                    }
                    
                }
            if (-not $foundDefaultValue) {
                Write-Error "CreateUIDefinition parameter '$paramName' default value '$mainTemplateDefault' is not allowed in the main template parameter '$($theOutput.Name)'" -ErrorId Allowed.Value.Default.Mismatch
            }            
        }
    }
}
