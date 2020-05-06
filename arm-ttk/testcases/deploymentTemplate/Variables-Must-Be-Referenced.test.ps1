<#
.Synopsis
    Ensures that all variables are referenced 
.Description
    Ensures that all variables declared in a template are in elsewhere in the template.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    [Parameter(Mandatory = $true, Position = 1)]
    [PSObject]
    $TemplateText
)

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
foreach ($variable in $TemplateObject.variables.psobject.properties) {
    
    # TODO: if the variable name is "copy": we need to loop through the array and pull each var and check individually
    
    if ($variable.name -ne 'copy' ) {
        # Create a Regex to find the variable
        $findVariable = [Regex]::new(@"
variables            # the variables keyword
\s{0,}               # optional whitespace
\(                   # opening parenthesis
\s{0,}               # more optional whitespace
'                    # a single quote
$($Variable.Name)    # the variable name
'                    # either a single quote
\s{0,}               # more optional whitespace
\)                   # closing parenthesis
"@,
    # The Regex needs to be case-insensitive
'Multiline,IgnoreCase,IgnorePatternWhitespace'
)

        $foundRefs = @($findVariable.Matches($TemplateText))
        if (-not $foundRefs) {
            Write-Error -Message "Unreferenced variable: $($Variable.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $variable
        } else {
            foreach ($fr in $foundRefs) {
                $foundQuote =$exprStrOrQuote.Match($TemplateText, $fr.Index)                
                if ($foundQuote.Value -eq '"') {
                    Write-Error -Message "Unreferenced variable: $($Variable.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $variable
                }
            }
        }        
    } else {
        foreach ($copyItem in $variable.value) {
            # Create a Regex to find the variable
            $findVariable = [Regex]::new(@"
variables            # the variables keyword
\s{0,}               # optional whitespace
\(                   # opening parenthesis
\s{0,}               # more optional whitespace
'                    # a single quote
$($copyItem.Name)    # the variable name
'                    # either a single quote
\s{0,}               # more optional whitespace
\)                   # closing parenthesis
"@,
    # The Regex needs to be case-insensitive
'Multiline,IgnoreCase,IgnorePatternWhitespace'
)
        
            $foundRefs = @($findVariable.Matches($TemplateText))
            if (-not $foundRefs) {
                Write-Error -Message "Unreferenced variable: $($copyItem.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $copyItem
            } else {
                foreach ($fr in $foundRefs) {
                    $foundQuote = $exprStrOrQuote.Match($TemplateText, $fr.Index)
                    if ($foundQuote.Value -eq '"') {
                        Write-Error -Message "Unreferenced variable: $($copyItem.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $copyItem
                    }
                }
            }
        }
    }
}