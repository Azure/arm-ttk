<#
.Synopsis
    Ensures that all variables are referenced 
.Description
    Ensures that all variables declared in a template are referenced elsewhere in the template.
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $TemplateText
)

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
foreach ($variable in $TemplateObject.variables.psobject.properties) {
    
    # TODO: if the variable name is "copy": we need to loop through the array and pull each var and check individually
    
    if ($variable.name -ne 'copy' -and $variable.value.copy -eq $null) {        
        $foundRefs = $TemplateText | ?<ARM_Variable> -Variable $variable.Name        
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
            $foundRefs = $TemplateText | ?<ARM_Variable> -Variable $copyItem.Name
            if (-not $foundRefs) {
                # if we have not found a reference for that variable, see if we have a dotted property of this name within the main variable reference.
                $foundMainVariable = $TemplateText | ?<ARM_Variable> -Variable $variable.Name
                $isOk = $true
                if (-not $foundMainVariable) { 
                    $isOk = $false
                }
                if ($TemplateText.Substring($foundMainVariable.EndIndex + 1, $copyItem.Name.Length) -ne $copyItem.Name) {
                    $isOk = $false
                }
                if (-not $isOk) {
                    Write-Error -Message "Unreferenced variable: $($copyItem.Name)" -ErrorId Variables.Must.Be.Referenced -TargetObject $copyItem
                }
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
