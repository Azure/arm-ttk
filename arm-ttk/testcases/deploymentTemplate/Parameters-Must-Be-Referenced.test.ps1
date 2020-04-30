<#
.Synopsis
    Ensures that parameters are referenced
.Description
    Ensures that all Azure Resource Manager Template
#>
param(
    # The Template Object
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    # The Template JSON Text
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateText
)

$TemplateObjectCopy = [PSObject]::new()
foreach ($prop in $TemplateObject.psobject.properties) {
    if ($prop.Name -eq 'Parameters') { continue }
    $TemplateObjectCopy.psobject.Members.Add($prop)    
}

$TemplateTextWithoutParameters = 
    $TemplateObjectCopy | ConvertTo-Json -Depth 100

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
foreach ($parameter in $TemplateObject.parameters.psobject.properties) {
    # If the parameter name starts with two underscores,
    if ($parameter.Name -like '__*') { continue } # skip it.


    # Create a Regex to find the var
    $findVar = [Regex]::new(@"
parameters           # the parameters keyword
\s{0,}               # optional whitespace
\(                   # opening parenthesis
\s{0,}               # more optional whitespace
(?:'|\\u0027)        # either a single quote or an escaped single quote
$($Parameter.Name)   # the parameter name
(?:'|\\u0027)        # either a single quote or an escaped single quote
\s{0,}               # more optional whitespace
\)                   # closing parenthesis
"@,
    # The Regex needs to be case-insensitive
'Multiline,IgnoreCase,IgnorePatternWhitespace'
)
    $foundRefs = @($findVar.Matches($TemplateTextWithoutParameters)) # See if we found the variable
    if (-not $foundRefs) { # If we didn't, error
        Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
    } else {
        foreach ($fr in $foundRefs) { # Walk thru each reference
            $foundQuote =$exprStrOrQuote.Match($TemplateTextWithoutParameters, $fr.Index) # make sure we hit a [ before a quote
            if ($foundQuote.Value -eq '"') { # if we don't, error
                Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
            }
        }
    }
}