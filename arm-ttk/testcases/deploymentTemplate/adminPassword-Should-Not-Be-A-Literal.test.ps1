<#
.Synopsis
    Ensures that all adminPasswords are expressions
.Description
    Ensures that all properties within a template named adminPassword are expressions, not literal strings
#>
param(
    [Parameter(Mandatory = $true)]
    [PSObject]
    $TemplateObject
)

# Find all references to an adminPassword
# Filtering the complete $TemplateObject directly fails with "The script failed due to call depth overflow." errors
function Check-PasswordsInTemplate {
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $TemplateObject,
        [Parameter(Mandatory = $true)]
        [string]
        $AdminPwd
    )
    if ("resources" -in $TemplateObject.PSobject.Properties.Name) {
        $adminPwdRefsResources = $TemplateObject.resources |
        Find-JsonContent -Key $AdminPwd  -Value * -Like 
    
        foreach ($ref in $adminPwdRefsResources) {
            # Walk over each one
            # if the property is not a string, then it's likely a param value for a nested deployment, and we should skip it.
            $a = $ref.$AdminPwd
            if ($a -isnot [string]) { 
                #check to see if this is a param value on a nested deployment - it will have a value property
                if ($a.value -is [string]) {
                    $trimmedPwd = "$($a.value)".Trim()
                }
                else {
                    continue # since we don't know what object shape we're testing at this point (could be a param declaration on a nested deployment)
                }
            }
            else {
                $trimmedPwd = "$($a)".Trim()
            }
            if ($trimmedPwd -notmatch '\[[^\]]+\]') {
                # If they aren't expressions
                Write-Error -TargetObject $ref -Message "AdminPassword `"$trimmedPwd`" is not an expression" -ErrorId AdminPassword.Is.Literal # write an error
                continue # and move onto the next
            }
        }
    }
    
    if ("variables" -in $TemplateObject.PSobject.Properties.Name) {
        $adminPwdRefsVariables = $TemplateObject.variables |
        Find-JsonContent -Key $AdminPwd  -Value * -Like
    
        foreach ($ref in $adminPwdRefsVariables) {
            # Walk over each one
            # if the property is not a string, then it's likely a param value for a nested deployment, and we should skip it.
            if ($ref.$AdminPwd -isnot [string]) { continue }
            $trimmedPwd = "$($ref.$AdminPwd)".Trim()
            if ($trimmedPwd -notmatch '\[[^\]]+\]') {
                # If they aren't expressions
                Write-Error -TargetObject $ref -Message "AdminPassword `"$trimmedPwd`" is variable which is not an expression" -ErrorId AdminPassword.Var.Is.Literal # write an error
                continue # and move onto the next
            }
        }
    
        # TODO - irregular doesn't handle null gracefully so we need to test for it
        if ($trimmedPwd -ne $null) {
            $PwdHasVariable = $trimmedPwd | ?<ARM_Variable> -Extract
            # this will return the outer most function in the expression
            $PwdHasFunction = $trimmedPwd | ?<ARM_Template_Function> -Extract
    
            # If we had a variable reference (not inside of another function) - then check it
            # TODO this will not flag things like concat so we should add a blacklist here to ensure it's still not a static or deterministic password
            if ($PwdHasVariable -and $PwdHasFunction.FunctionName -eq 'variables') { 
                $variableValue = $TemplateObject.variables.($PwdHasVariable.VariableName)
                $variableValueExpression = $variableValue | ?<ARM_Template_Expression>
                if (-not $variableValueExpression) {
                    Write-Error "AdminPassword references variable '$($PwdHasVariable.variableName)', which has a literal value. " -ErrorId AdminPassword.Is.Variable.Literal # write an error
                }
            }
        }
    }
}

$pwdValues = @("administratorLoginPassword", "adminPassword")
foreach ($pwdValue in $pwdValues) {
    Check-PasswordsInTemplate -TemplateObject $TemplateObject -AdminPwd $pwdValue
}
