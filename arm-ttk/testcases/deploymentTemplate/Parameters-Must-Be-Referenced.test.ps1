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

$lineBreaks = [Regex]::Matches($TemplateText, "`n|$([Environment]::NewLine)")

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
foreach ($parameter in $TemplateObject.parameters.psobject.properties) {
    # If the parameter name starts with two underscores,
    if ($parameter.Name -like '__*') { continue } # skip it.

    $escapedName = $parameter.Name -replace '\s', '\s'
    # Create a Regex to find the parameter

    $foundRefs = $TemplateText | ?<ARM_Parameter> -Parameter $escapedName
    if (-not $foundRefs) { # If we didn't, error
        Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
    } else {
        foreach ($fr in $foundRefs) { # Walk thru each reference
            $foundQuote =$exprStrOrQuote.Match($TemplateText, $fr.Index + 1) # make sure we hit a [ before a quote
            if ($foundQuote.Value -eq '"') { # if we don't, error
                $lineNumber = @($lineBreaks | ? { $_.Index -lt $fr.Index }).Count + 1    
                $targetObject = $parameter.PsObject.Copy()
                $targetObject | Add-Member -MemberType NoteProperty -Name lineNumber -Value $lineNumber
                Write-Error -Message "Parameter reference is not contained within an expression: $($Parameter.Name) on line: $lineNumber" -ErrorId Parameters.Must.Be.Referenced.In.Expression -TargetObject $targetObject
            }
        }
    }
}
