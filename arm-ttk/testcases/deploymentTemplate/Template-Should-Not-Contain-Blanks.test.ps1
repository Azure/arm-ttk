param(
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateText
)

# Check for any text to remove empty property values - PowerShell handles empty differently in objects so check the JSON source (i.e. text)
# Empty strings, arrays, objects and null property values are not allowed, they have specific meaning in a declarative model
# the part of the expression '(?<=:)' is a back reference that means the expression must follow a colon, 
#   but the colon is not part of the match
#   this ensures that the $PropertiesThatCanBeEmpty exceptions don't include the colon in the property name when we search
#   the nearby context below

$colon = "(?<=:)\s{0,}" # this a back reference for a colon followed by 0 to more whitespace

$emptyItems = @([Regex]::Matches($TemplateText, "${colon}\{\s{0,}\}")) + # Empty objects
              @([Regex]::Matches($TemplateText, "${colon}\[\s{0,}\]")) + # empty arrays
              @([Regex]::Matches($TemplateText, "${colon}`"\s{0,}`"")) + # empty strings
              @([Regex]::Matches($TemplateText, "${colon}null"))

# TODO: This test will flag things like json('null') - that needs to be fixed before we add a check for null
# @([Regex]::Matches($TemplateText, 'null')) # null json property value

$lineBreaks = [Regex]::Matches($TemplateText, "`n|$([Environment]::NewLine)")

# Some properties can be empty for readability
$PropertiesThatCanBeEmpty = 'resources', 
                            'outputs', 
                            'variables', 
                            'parameters', 
                            'functions', 
                            'properties', 
                            'defaultValue', # enables optional parameters
                            'accessPolicies',  # keyVault requires this
                            'value', # Microsoft.Resources/deployments - passing empty strings to a nested deployment
                            'promotionCode', # Microsoft.OperationsManagement/soltuions/plan object
                            'inputs' # Microsoft.Portal/dashboard

if ($emptyItems) {
    foreach ($emptyItem in $emptyItems) {
        $nearbyContext = [Regex]::new('"(?<PropertyName>[^"]{1,})"\s{0,}:', "RightToLeft").Match($TemplateText, $emptyItem.Index)
        if ($nearbyContext -and $nearbyContext.Success) {
            $emptyPropertyName = $nearbyContext.Groups["PropertyName"].Value
            if ($PropertiesThatCanBeEmpty -contains $emptyPropertyName) {
                continue
            }
            $lineNumber = @($lineBreaks | ? { $_.Index -lt $emptyItem.Index }).Count + 1
            Write-Error "Empty property: $emptyItem found on line: $lineNumber" -TargetObject $emptyItem
        } 
    }
}