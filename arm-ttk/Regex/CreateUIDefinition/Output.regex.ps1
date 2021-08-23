<#
.Synopsis
    Matches an Output containing an element
.Description
    Matches a CreateUIDefinition output that contains an element name (references to steps or basics)    
#>
param(
# The name of the control.  By default, matches any control not in steps.
[string]
$ControlName = '\w+',

# The name of the step.
[string]
$StepName
)


if ($StepName) {
@"
    steps\(
        \s{0,}
        '(?<StepName>$StepName)'
        \s{0,}
    \)
    (?:
        \.
        (?<Property>\w+)
    ){0,}?(?=\z|\.${ControlName})
    \.${ControlName}
"@
} else {
@"

    basics\(
        \s{0,}
        '(?<ControlName>$ControlName)'
        \s{0,}
    \)
    (?:
        \.
        (?<Property>\w+)
    ){0,}

"@
}
