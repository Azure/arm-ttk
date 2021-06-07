<#
.Synopsis
    Ensures that all adminUsernames are expressions
.Description
    Ensures that all properties within a template named adminUsername are expressions, not literal strings
#>
param(
    [Parameter(Mandatory = $true)]
    [PSObject]
    $TemplateObject
)

# Find all references to an adminUserName
# Filtering the complete $TemplateObject directly fails with "The script failed due to call depth overflow." errors

if ("resources" -in $TemplateObject.PSobject.Properties.Name) {
    $adminUserNameRefsResources = $TemplateObject.resources |
    Find-JsonContent -Key adminUsername  -Value * -Like 

    foreach ($ref in $adminUserNameRefsResources) {
        # Walk over each one
        # if the property is not a string, then it's likely a param value for a nested deployment, and we should skip it.
        $a = $ref.adminUsername
        if ($a -isnot [string]) { 
            #check to see if this is a param value on a nested deployment - it will have a value property
            if ($a.value -is [string]) {
                $trimmedUserName = "$($a.value)".Trim()
            }
            else {
                continue # since we don't know what object shape we're testing at this point (could be a param declaration on a nested deployment)
            }
        }
        else {
            $trimmedUserName = "$($a)".Trim()
        }
        if ($trimmedUserName -notmatch '\[[^\]]+\]') {
            # If they aren't expressions
            Write-Error -TargetObject $ref -Message "AdminUsername `"$trimmedUserName`" is not an expression" -ErrorId AdminUsername.Is.Literal # write an error
            continue # and move onto the next
        }
    }
}

if ("variables" -in $TemplateObject.PSobject.Properties.Name) {
    $adminUserNameRefsVariables = $TemplateObject.variables |
    Find-JsonContent -Key adminUsername  -Value * -Like

    foreach ($ref in $adminUserNameRefsVariables) {
        # Walk over each one
        # if the property is not a string, then it's likely a param value for a nested deployment, and we should skip it.
        if ($ref.adminUserName -isnot [string]) { continue }
        $trimmedUserName = "$($ref.adminUserName)".Trim()
        if ($trimmedUserName -notmatch '\[[^\]]+\]') {
            # If they aren't expressions
            Write-Error -TargetObject $ref -Message "AdminUsername `"$trimmedUserName`" is variable which is not an expression" -ErrorId AdminUsername.Var.Is.Literal # write an error
            continue # and move onto the next
        }
    }

    # TODO - irregular doesn't handle null gracefully so we need to test for it
    if ($trimmedUserName -ne $null) {
        $UserNameHasVariable = $trimmedUserName | ?<ARM_Variable> -Extract
        # this will return the outer most function in the expression
        $userNameHasFunction = $trimmedUserName | ?<ARM_Template_Function> -Extract

        # If we had a variable reference (not inside of another function) - then check it
        # TODO this will not flag things like concat so we should add a blacklist here to ensure it's still not a static or deterministic username
        if ($UserNameHasVariable -and $userNameHasFunction.FunctionName -eq 'variables') { 
            $variableValue = $TemplateObject.variables.($UserNameHasVariable.VariableName)
            $variableValueExpression = $variableValue | ?<ARM_Template_Expression>
            if (-not $variableValueExpression) {
                Write-Error @"
AdminUsername references variable '$($UserNameHasVariable.variableName)', which has a literal value.
"@ -ErrorId AdminUserName.Is.Variable.Literal # write an error
            }
        }
    }
}
