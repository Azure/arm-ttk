<#
.Synopsis
    Ensures PasswordBoxes had a Minimum Length
.Description
    Ensures PasswordBoxes had a Regex Constraint with a minimum length of as least 12 characters
#>
param(
# The createUIDefintion Object
[Parameter(Mandatory=$true)]
[PSObject]
$CreateUIDefinitionObject,

# The Password Minimum Length
[int]
$PasswordMinLength = 12
)

# First, find all password boxes.
$passwordBoxes = $CreateUIDefinitionObject | 
    Find-JsonContent -Key type -Value Microsoft.Common.PasswordBox
    
$lengthConstraintRegex = [Regex]::new('\{(?<Min>\d+),(?<Max>\d+)?\}\$$')

foreach ($pwb in $passwordBoxes) { # Loop over each password box
    if (-not $pwb.constraints) {
        Write-Error "PasswordBox '$($pwb.name)' is missing constraints" -TargetObject $pwb
        continue
    }
    if (-not $pwb.constraints.regex) { # If there is no regex, the default will meet the complexity requirements.
        continue
    }

    try { # If it did,
        $constraintWasRegex = [Regex]::new($textbox.constraints.regex) # try to cast to a regex
        $hasLengthConstraint = $lengthConstraintRegex.Match($pwb.constraints.regex)

        if (-not $hasLengthConstraint.Success) {
            Write-Error "PasswordBox '$($pwb.Name)' regex does not have a length constraint." -TargetObject $pwb 
        } else {
            if ($passWordMinLength -gt $hasLengthConstraint.Groups['Min'].Value) {
                Write-Error "PasswordBox '$($pwb.Name)' regex does not have a minimum length of $PasswordMinLength" -TargetObject $pwb
            }
        }
    } catch {
        $err = $_ # if that fails, 
        Write-Error "PasswordBox '$($pwb.Name)' regex is invalid: $($err)" -TargetObject $pwb #error.
    }
}
