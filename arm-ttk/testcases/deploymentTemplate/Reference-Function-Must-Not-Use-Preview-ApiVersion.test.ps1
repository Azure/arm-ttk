<#
.Synopsis
    Ensures that reference functions do not use preview ApiVersions.
.Description
    Ensures that the uses of the reference() functions within an 
    Azure Resource Manager template do not refer to a -preview.
#>
param(
[Parameter(Mandatory)]
[string]
$TemplateText
)

$matchSegments = 
    'reference',
    '\(',
        "'(?<ResourceName>[^']+)'",
        ',',
        "'(?<ApiVersion>[^']+)'"

$referenceWithApiVersion = [Regex]::new(
    $matchSegments -join ([Environment]::NewLine + '\s?' + [Environment]::NewLine), 
    'IgnoreCase,IgnorePatternWhitespace')

foreach ($match in $referenceWithApiVersion.Matches($TemplateText)) {
    if ($match.Groups['ApiVersion'] -like '*-preview') {
        Write-Error "Referencing a -preview apiversion for $($match.Groups['ResourceName'])" -TargetObject $match
    }
}
