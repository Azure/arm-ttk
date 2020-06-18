<#
.Synopsis

.Description

#>
param(
[Parameter(Mandatory)]
[string]
$TemplateText
)


# Because so many parts of an Azure Resource Manager expression allow whitespace, 
# it's easier to create a Regex by listing all of the segments 
$matchSegments = 
    'variables',
    '\(',
        'concat',
            '\(',
                "'(?<VariableName>[^']+)'",
            '\)',
        ',',
        'parameters',
            '\(',
                "'(?<ParameterName>[^']+)'",
            '\)',
    '\)'

$DynamicCompatReference = [Regex]::new(
    $matchSegments -join ([Environment]::NewLine + '\s?' + [Environment]::NewLine), 
    'IgnoreCase,IgnorePatternWhitespace')

foreach ($match in $DynamicCompatReference.Matches($TemplateText)) {
    $rewriteMsg = "variables('$($match.Groups['VariableName'])')[parameters('$($match.Groups['ParameterName'])']"
    
    Write-Error "Dynamic Variable References should not use concat.  Suggested: $rewriteMsg" -ErrorId 'DynamicVariable.Reference.Using.Concat' -TargetObject $match
}