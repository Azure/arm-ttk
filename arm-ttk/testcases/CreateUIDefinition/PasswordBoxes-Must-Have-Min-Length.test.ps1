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
    
$lengthConstraintRegex = [Regex]::new('\{(?<Min>\d+)')

foreach ($pwb in $passwordBoxes) { # Loop over each password box
    if (-not $pwb.constraints) {
        Write-Error "PasswordBox '$($pwb.name)' is missing constraints" -TargetObject $pwb
        continue
    }
    if (-not $pwb.constraints.regex) { # If there is no regex, the default will meet the complexity requirements.
        continue
    }

    if ($pwb.constraints.regex -match '^\s{0,}\[' -and 
        $pwb.constraints.regex -match '\]\s{0,}$') { # If the constraint Regex is an expression
        continue # continue, as we don't want it to error and we cannot judge complexity of the expression result.
    }

    try { # If it did,
        $constraintWasRegex = [Regex]::new($pwb.constraints.regex) # try to cast to a regex
        $hasLengthConstraint = $lengthConstraintRegex.Matches($pwb.constraints.regex)

        if (-not $hasLengthConstraint) {
            Write-Error "PasswordBox '$($pwb.Name)' regex does not have a length constraint." -TargetObject $pwb 
        } else {
            $totalMins = 0
            foreach ($match in $hasLengthConstraint) {
                $totalMins += $match.Groups['Min'].Value -as [int]
            }
            if ($passWordMinLength -gt $totalMins) {
                Write-Warning "PasswordBox '$($pwb.Name)' regex does not have a minimum length of $PasswordMinLength"
            }
        }
    } catch {
        $err = $_ # if that fails, 
        Write-Error "PasswordBox '$($pwb.Name)' regex is invalid: $($err)" -TargetObject $pwb #error.
    }
}
