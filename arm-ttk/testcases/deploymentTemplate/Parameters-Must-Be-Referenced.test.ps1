param(
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateText
)

<# REGEX
- 
- parameters
- whitespace
- ('
- whitespace
- <ParameterName>
- whitespace
- ')

An expression could be: "[ concat ( variables ( 'test' ), ...)]"

#>
$exprStrOrQuote = [Regex]::new('(?<!\\)(?>"\s{0,}\[")', 'RightToLeft')
foreach ($parameter in $TemplateObject.parameters.psobject.properties) {
    $findVar = [Regex]::new("parameters\s{0,}\(\s{0,}'$($Parameter.Name)'\s{0,}\)")
    $foundRefs = @($findVar.Matches($TemplateText))
    if (-not $foundRefs) {
        Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
    } else {
        foreach ($fr in $foundRefs) {
            $foundQuote =$exprStrOrQuote.Match($TemplateText, $fr.Index)                
            if ($foundQuote.Value -eq '"') {
                Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
            }
        }
    }
}