<#
.Synopsis
    Ensures that TextBox controls are well formed.
.Description
    Ensures that TextBox controls are well formed, including having a validation Regular Expression.
#>
param(
# The contents of CreateUIDefintion, converted from JSON.
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$CreateUIDefinitionObject
)

# First, find all textboxes within CreateUIDefinition.

$allTextBoxes = $CreateUiDefinitionObject | Find-JsonContent -Key type -value Microsoft.Common.TextBox
$lengthConstraintRegex = [Regex]::new('\{(?<Min>\d+),(?<Max>\d+)?\}(\$)?$')

foreach ($textbox in $allTextBoxes) { # Then we walk over each textbox.
    if (-not $textbox.constraints) { # If constraints was missing or blank,
        Write-Error "Textbox $($textbox.Name) is missing constraints" -TargetObject $textbox # error
        continue # and continue (since additional failures would be noise).
    }    
    if (-not $textbox.constraints.regex) { # If the constraint didn't have a regex,
        Write-Error "Textbox $($textbox.Name) is missing constraints.regex" -TargetObject $textbox #error.
    } else {        
        try { # If it did,
            $constraintWasRegex = [Regex]::new($textbox.constraints.regex) # try to cast to a regex
            $hasLengthConstraint = $lengthConstraintRegex.Match($textbox.constraints.regex)

            if (-not $hasLengthConstraint.Success) {
                Write-Warning "TextBox '$($textBox.Name)' regex does not have a length constraint." 
            }
        } catch {
            $err = $_ # if that fails, 
            Write-Error "Textbox $($textbox.Name) regex is invalid: $($err)" -TargetObject $textbox #error.
        }
    }
    if (-not $textbox.constraints.validationMessage) { # If there's not a validation message
        Write-Error "Textbox $($textbox.Name) is missing constraints.validationMessage" -TargetObject $textbox #error.
    }
}