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

$lineBreaks = [Regex]::Matches($TemplateText, "`n|$([Environment]::NewLine)")

$innerTemplates = $TemplateText | ?<ARM_InnerTemplate> 

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
foreach ($variable in $TemplateObject.variables.psobject.properties) {
    
    # if the variable name is "copy": we need to loop through the array and pull each var and check individually
    $escapedName = $variable.Name -replace '\s', '\s'


    if ($variable.name -ne 'copy' -and $variable.value.copy -eq $null) {        
        $foundRefs = $TemplateText | 
            ?<ARM_Variable> -Variable $escapedName |
            Where-Object { 
                $Ref = $_
                if (-not $innerTemplates) { return $true }
                -not ($innerTemplates | Where-Object { 
                    $ref.Index -gt $_.Index -and
                    $ref.Index -lt ($_.index + $_.Length)
                })
            }
        if (-not $foundRefs) {
            Write-Error -Message "Unreferenced variable: $($Variable.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $variable
        } else {
            foreach ($fr in $foundRefs) {
                $foundQuote =$exprStrOrQuote.Match($TemplateText, $fr.Index)                
                if ($foundQuote.Value -eq '"') {
                    Write-Error -Message "Variable reference is not contained within an expression: $($copyItem.Name)" -ErrorId Variables.Must.Be.Referenced.In.Expression -TargetObject $copyItem
                }
            }
        }        
    } else {
        $copyItemList = 
            if ($variable.Name -eq 'copy') {
                $variable.value
            } else {
                $variable.value.copy
            }
        foreach ($copyItem in $copyItemList) {
            $foundRefs = $TemplateText | 
                ?<ARM_Variable> -Variable $escapedName |
                Where-Object { 
                    $Ref = $_
                    if (-not $innerTemplates) { return $true }
                    -not ($innerTemplates | Where-Object { 
                        $ref.Index -gt $_.Index -and
                        $ref.Index -lt ($_.index + $_.Length)
                    })
                }
            if (-not $foundRefs) {
                Write-Error -Message "Unreferenced variable: $($copyItem.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $copyItem
            } else {
                foreach ($fr in $foundRefs) {
                    $foundQuote = $exprStrOrQuote.Match($TemplateText, $fr.Index)
                    if ($foundQuote.Value -eq '"') {
                        Write-Error -Message "Variable reference is not contained within an expression: $($copyItem.Name)" -ErrorId Variables.Must.Be.Referenced.In.Expression -TargetObject $copyItem
                    }
                }
            }
        }
    }
}
