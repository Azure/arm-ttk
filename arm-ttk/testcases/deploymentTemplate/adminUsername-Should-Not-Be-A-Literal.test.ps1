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
    Find-JsonContent -Key adminUsername  -Value * -Like |
    Where-Object { -not $_.ParentObject[0].'$schema' } # unless they're on a top-level property.

    foreach ($ref in $adminUserNameRefsResources) {
        # Walk over each one
        $trimmedUserName = "$($ref.adminUserName)".Trim()
        if ($trimmedUserName -notmatch '\[[^\]]+\]') {
            # If they aren't expressions
            Write-Error -TargetObject $ref -Message "AdminUsername is not an expression" -ErrorId AdminUsername.Is.Literal # write an error
            continue # and move onto the next
        }
    }
}

if ("variables" -in $TemplateObject.PSobject.Properties.Name) {
    $adminUserNameRefsVariables = $TemplateObject.variables |
    Find-JsonContent -Key adminUsername  -Value * -Like |
    Where-Object { -not $_.ParentObject[0].'$schema' } # unless they're on a top-level property.

    foreach ($ref in $adminUserNameRefsVariables) {
        # Walk over each one
        $trimmedUserName = "$($ref.adminUserName)".Trim()
        if ($trimmedUserName -notmatch '\[[^\]]+\]') {
            # If they aren't expressions
            Write-Error -TargetObject $ref -Message "AdminUsername is not an expression" -ErrorId AdminUsername.Is.Literal # write an error
            continue # and move onto the next
        }
    }

    # TODO - irregular doesn't handle null gracefully so we need to test for it
    if ($trimmedUserName -ne $null) {
        $UserNameHasVariable = $trimmedUserName | ?<ARM_Variable> -Extract

        if ($UserNameHasVariable) {
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
