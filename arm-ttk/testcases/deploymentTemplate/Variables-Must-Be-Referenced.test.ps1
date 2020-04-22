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

<# REGEX
- 
- variables
- whitespace
- ('
- whitespace
- <VariableName>
- whitespace
- ')

An expression could be: "[ concat ( variables ( 'test' ), ...)]"

#>

# TODO: Need to properly check for variable copy, see: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-multiple#variable-iteration

$exprStrOrQuote = [Regex]::new('(?<!\\)(?>"\s{0,}\[|")', 'RightToLeft')

foreach ($variable in $TemplateObject.variables.psobject.properties) {
    
    # TODO: if the variable name is "copy": we need to loop through the array and pull each var and check individually
    
    if ($variable.name -ne 'copy' ) {
        $findVar = [Regex]::new("variables\s{0,}\(\s{0,}'$($Variable.Name)'\s{0,}\)")
        $foundRefs = @($findVar.Matches($TemplateText))
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
    }
}