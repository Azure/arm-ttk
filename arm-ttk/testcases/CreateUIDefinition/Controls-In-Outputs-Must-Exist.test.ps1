<#
.Synopsis
    Ensures that controls in Outputs exist
.Description
    Ensures that controls in Outputs are defined elsewhere in CreateUIDefinition
#>
param(
# The CreateUIDefinition Object
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$CreateUIDefinitionObject
)

$basicsOrSteps = [Regex]::new(@'
\s{0,}       # Optional whitespace
\[           # opening bracket
\s{0,}       # optional whitespace
(?>          # Either 
    basics\( # Basics
    \s{0,}   # More whitespace
    '        # and a ControlName between quotes
    (?<ControlName>[^']+)
    '         
    |        # Or
    steps\(  # Steps
        \s{0,}  # more whitespace
        '    # Stepname between quotes
        (?<StepName>[^']+)
        '
        \s{0,}
    \)       # closing parenthesis
    (\.
       (?<ElementName>\w+) # optional element name after a .
    )?
)
'@, 'IgnoreCase,IgnorePatternWhitespace')

foreach ($CreateUIOutput in $CreateUIDefinitionObject.parameters.outputs.psobject.properties) {
    $expression = $CreateUIOutput.Value 
    $matched = @(
        if ($expression -is [string]) {
            $basicsOrSteps.Matches($expression)
        }
        else {
            foreach ($prop in $expression.psobject.properties) {
                # TODO this only goes one level deep on the object will have to see if deeper objects surface in the wild
                if ($prop.value -is [string]) {
                    $basicsOrSteps.Matches($prop.value)
                }
            }
        }
    )

    foreach ($match in $matched) {
        if (-not $match.Success) { continue }
        $controlName = $match.Groups['ControlName'].Value
        
        if ($controlName) {
            $FoundControl = $CreateUIDefinitionObject.parameters.basics | 
                Where-Object Name -EQ $ControlName
            if (-not $FoundControl) {
                Write-Error "Could not find control '$controlName' in .parameters.basics" -ErrorId ControlName.Not.Found -TargetObject $match
            }
        }

        $stepName = $match.Groups['StepName'].Value
        if ($stepName) {
            $FoundStep = $CreateUIDefinitionObject.parameters.steps | 
                Where-Object Name -EQ $stepName
            if (-not $FoundStep) {
                Write-Error "Could not find step '$stepName' in .parameters.steps" -ErrorId StepName.Not.Found -TargetObject $match
            } else {
                $elementName = $match.Groups['ElementName'].Value
                if ($elementName) {
                    $foundElement = $FoundStep.Elements | 
                        Where-Object Name -eq $elementName

                    if (-not $foundElement) {
                        Write-Error "Count not find element '$elementName' in .parameters.steps.$stepName" -ErrorId ElementName.Not.Found -TargetObject $match
                    }
                }
            }
        }
    }
}
