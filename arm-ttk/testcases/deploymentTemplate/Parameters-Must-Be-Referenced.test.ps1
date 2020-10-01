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

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
foreach ($parameter in $TemplateObject.parameters.psobject.properties) {
    # If the parameter name starts with two underscores,
    if ($parameter.Name -like '__*') { continue } # skip it.

    $escapedName = $Parameter.Name -replace '\s', '\s'
    # Create a Regex to find the parameter
    $findParam = [Regex]::new(@"
parameters    # the parameters keyword
\s{0,}        # optional whitespace
\(            # opening parenthesis
\s{0,}        # more optional whitespace
'             # a single quote
$escapedName  # the parameter name
'             # a single quote
\s{0,}        # more optional whitespace
\)            # closing parenthesis
"@,
    # The Regex needs to be case-insensitive
'Multiline,IgnoreCase,IgnorePatternWhitespace'
)
    $foundRefs = @($findParam.Matches($TemplateText)) # See if we found the parameter
    if (-not $foundRefs) { # If we didn't, error
        Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
    } else {
        foreach ($fr in $foundRefs) { # Walk thru each reference
            $foundQuote =$exprStrOrQuote.Match($TemplateText, $fr.Index + 1) # make sure we hit a [ before a quote
            if ($foundQuote.Value -eq '"') { # if we don't, error
                Write-Error -Message "Parameter reference is not contained within an expression: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced.In.Expression -TargetObject $parameter
            }
        }
    }
}
