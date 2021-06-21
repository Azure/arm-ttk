<#
.Synopsis
    Matches an Output containing an element
.Description
    Matches a CreateUIDefinition output that contains an element name (references to steps or basics)    
#>
param(
# The name of the element.  By default, matches any element.
[string]
$ElementName = '\w+'
)

@"
(?>
    steps\(
        \s{0,}
        '(?<ElementName>$ElementName)'
        \s{0,}
    \)
    (?:
        \.
        (?<Property>\w+)
    ){0,}
|
    basics\(
        \s{0,}
        '(?<ElementName>$ElementName)'
        \s{0,}
    \)
    (?:
        \.
        (?<Property>\w+)
    ){0,}
|
    steps\(
        \s{0,}
        '(?<StepName>\w+)'
        \s{0,}
    \)
    (?:
        \.
        (?<Property>\w+)
    ){0,}?(?=\z|\.${elementName})
    \.${elementName}
)
"@
