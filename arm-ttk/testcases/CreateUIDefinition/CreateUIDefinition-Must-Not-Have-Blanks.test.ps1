<#
.Synopsis
    Ensures CreateUIDefinition does not contain blanks
.Description
    Ensures CreateUIDefinition does not contain blanks, except if it one of the following properties:

    * Resources
    * DefaultValue
#>
param(
# The text of CreateUIDefinition.json
[Parameter(Mandatory)]
[string]
$CreateUIDefinitionText
)

$colon = "(?<=:)\s{0,}" # this a back reference for a colon followed by 0 to more whitespace

$emptyItems = 
    @([Regex]::Matches($CreateUIDefinitionText, "${colon}\{\s{0,}\}")) + # Empty objects
    @([Regex]::Matches($CreateUIDefinitionText, "${colon}\[\s{0,}\]")) + # empty arrays
    @([Regex]::Matches($CreateUIDefinitionText, "${colon}`"\s{0,}`"")) + # empty strings
    @([Regex]::Matches($CreateUIDefinitionText, "${colon}\[\s{0,}\{\s{0,}\}\s{0,}\]")) + # empty arrays containing empty objects 
    @([Regex]::Matches($CreateUIDefinitionText, "${colon}\[\s{0,}`"\s{0,}`"\s{0,}\]")) + # empty arrays containing empty objects  
    @([Regex]::Matches($CreateUIDefinitionText, "${colon}null"))

$lineBreaks = [Regex]::Matches($CreateUIDefinitionText, "`n|$([Environment]::NewLine)")

$PropertiesThatCanBeEmpty = @('basics','defaultValue', 'steps')

if ($emptyItems) {
    foreach ($emptyItem in $emptyItems) {
        $nearbyContext = [Regex]::new('"(?<PropertyName>[^"]{1,})"\s{0,}:', "RightToLeft").Match($CreateUIDefinitionText, $emptyItem.Index)
        if ($nearbyContext -and $nearbyContext.Success) {
            $emptyPropertyName = $nearbyContext.Groups["PropertyName"].Value
            # exceptions
            if ($PropertiesThatCanBeEmpty -contains $emptyPropertyName) {
                continue
            }            
            $lineNumber = @($lineBreaks | ? { $_.Index -lt $emptyItem.Index }).Count + 1
            Write-Error "Empty property: $emptyPropertyName found on line: $lineNumber" -TargetObject $emptyItem
        } 
    }
}

