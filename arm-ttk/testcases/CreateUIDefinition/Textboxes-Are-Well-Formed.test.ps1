<#
.Synopsis
    Ensures that TextBox controls are well formed.
.Description
    Ensures that TextBox controls are well formed, including having a validation Regular Expression.
#>
param(
    # The contents of CreateUIDefintion, converted from JSON.
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $CreateUIDefinitionObject
)

# First, find all textboxes within CreateUIDefinition.
$allTextBoxes = $CreateUiDefinitionObject | Find-JsonContent -Key type -value Microsoft.Common.TextBox
# Regex Constraint should contain one of following pattern (Length Check): {m,n} or {m,} or {m}
$lengthContraintRegex = [Regex]::new('\{(?<Min>\d+)(?:,(?<Max>\d+)|,)?\}')

foreach ($textbox in $allTextBoxes) {
    # Then we walk over each textbox.
    if (-not $textbox.constraints) {
        # If constraints was missing or blank,
        Write-Error -Message "Textbox $($textbox.Name) is missing constraints" -ErrorId Textboxes.Are.Well.Formed.Missing.Constraints -TargetObject $textbox # error
        continue # and continue (since additional failures would be noise).
    }

    $constraintRegexString = "";
    if ($textbox.constraints.validations) {
        $constraintRegexString = foreach ($validation in $textbox.constraints.validations) {
            if ($validation.regex) { 
                $validation.regex; break
            }
        }
    }
    elseif ($textbox.constraints.regex) {
        $constraintRegexString = $textbox.constraints.regex
        if (-not $textbox.constraints.validationMessage) {
            # Regex constraint is missing validation message
            Write-Error -Message "Textbox $($textbox.Name) is missing constraints.validationMessage" -ErrorId Textboxes.Are.Well.Formed.Missing.Constraints.ValidationMessage -TargetObject $textbox #error.
        }
    }

    if (-not $constraintRegexString ) {
        # If the constraint didn't have a regex
        Write-Error -Message "Textbox $($textbox.Name) is missing constraints.regex or regex property in constraints.validations" -ErrorId Textboxes.Are.Well.Formed.Missing.Constraints.Regex -TargetObject $textbox #error.
    }
    else {
        try {
            # If it did
            $constraintWasRegex = [Regex]::new($constraintRegexString) # try to cast to a regex
            $hasLengthConstraint = $lengthContraintRegex.Match($constraintRegexString)
    
            if (-not ($hasLengthConstraint.Success)) {
                Write-Warning "TextBox '$($textBox.Name)' regex does not have a length constraint." 
            }
        }
        catch {
            $err = $_ # if that fails
            Write-Error -Message "Textbox $($textbox.Name) regex is invalid: $($err)" -ErrorId Textboxes.Are.Well.Formed.Invalid.Constraints.Regex.Expressison -TargetObject $textbox #error.
        }
    }
}
